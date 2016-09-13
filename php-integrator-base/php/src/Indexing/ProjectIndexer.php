<?php

namespace PhpIntegrator\Indexing;

use PhpIntegrator\SourceCodeHelper;

/**
 * Handles project and folder indexing.
 */
class ProjectIndexer
{
    /**
     * @var StorageInterface
     */
    protected $storage;

    /**
     * @var BuiltinIndexer
     */
    protected $builtinIndexer;

    /**
     * @var FileIndexer
     */
    protected $fileIndexer;

    /**
     * @var Scanner
     */
    protected $scanner;

    /**
     * @var SourceCodeHelper
     */
    protected $sourceCodeHelper;

    /**
     * @var resource|null
     */
    protected $loggingStream;

    /**
     * @var resource|null
     */
    protected $progressStream;

    /**
     * @param StorageInterface $storage
     * @param BuiltinIndexer   $builtinIndexer
     * @param FileIndexer      $fileIndexer
     * @param Scanner          $scanner
     * @param SourceCodeHelper $sourceCodeHelper
     */
    public function __construct(
        StorageInterface $storage,
        BuiltinIndexer $builtinIndexer,
        FileIndexer $fileIndexer,
        Scanner $scanner,
        SourceCodeHelper $sourceCodeHelper
    ) {
        $this->storage = $storage;
        $this->builtinIndexer = $builtinIndexer;
        $this->fileIndexer = $fileIndexer;
        $this->scanner = $scanner;
        $this->sourceCodeHelper = $sourceCodeHelper;
    }

    /**
     * @return resource|null
     */
    public function getLoggingStream()
    {
        return $this->loggingStream;
    }

    /**
     * @param resource|null $loggingStream
     *
     * @return static
     */
    public function setLoggingStream($loggingStream)
    {
        $this->builtinIndexer->setLoggingStream($loggingStream);

        $this->loggingStream = $loggingStream;
        return $this;
    }

    /**
     * @return resource|null
     */
    public function getProgressStream()
    {
        return $this->progressStream;
    }

    /**
     * @param resource|null $progressStream
     *
     * @return static
     */
    public function setProgressStream($progressStream)
    {
        $this->progressStream = $progressStream;
        return $this;
    }

    /**
     * Logs a single message for debugging purposes.
     *
     * @param string $message
     */
    protected function logMessage($message)
    {
        if (!$this->loggingStream) {
            return;
        }

        fwrite($this->loggingStream, $message . PHP_EOL);
    }

    /**
     * Logs progress for streaming progress.
     *
     * @param int $itemNumber
     * @param int $totalItemCount
     */
    protected function sendProgress($itemNumber, $totalItemCount)
    {
        if (!$this->progressStream) {
            return;
        }

        if ($totalItemCount) {
            $progress = ($itemNumber / $totalItemCount) * 100;
        } else {
            $progress = 100;
        }

        fwrite($this->progressStream, $progress . PHP_EOL);
    }

    /**
     * Indexes the specified project.
     *
     * @param string[] $items
     * @param string[] $extensionsToIndex
     * @param string[] $excludedPaths
     * @param array    $sourceOverrideMap
     */
    public function index(array $items, array $extensionsToIndex, array $excludedPaths = [], $sourceOverrideMap = [])
    {
        $this->indexBuiltinItemsIfNecessary();

        $this->logMessage('Pruning removed files...');
        $this->pruneRemovedFiles();

        $this->logMessage('Scanning for files that need (re)indexing...');
        $files = $this->scanForFilesToIndex($items, $extensionsToIndex);
        $files = $this->getFilteredFilesToIndex($files, $excludedPaths);

        $this->logMessage('Indexing outline...');

        $totalItems = count($files);

        $this->sendProgress(0, $totalItems);

        $this->storage->beginTransaction();

        foreach ($files as $i => $filePath) {
            echo $this->logMessage('  - Indexing ' . $filePath);

            $code = isset($sourceOverrideMap[$filePath]) ?
                $sourceOverrideMap[$filePath] :
                $this->sourceCodeHelper->getSourceCode($filePath, false);

            try {
                $this->fileIndexer->index($filePath, $code);
            } catch (IndexingFailedException $e) {
                $this->logMessage('    - ERROR: Indexing failed due to parsing errors!');
            }

            $this->sendProgress($i+1, $totalItems);
        }

        $this->storage->commitTransaction();
    }

    /**
     * @param string[] $paths
     * @param string[] $extensionsToIndex
     *
     * @return string[]
     */
    protected function scanForFilesToIndex(array $paths, array $extensionsToIndex)
    {
        $files = [];

        foreach ($paths as $path) {
            if (is_dir($path)) {
                $filesInDirectory = $this->scanner->scan($path, $extensionsToIndex);

                $files = array_merge($files, $filesInDirectory);
            } elseif (is_file($path)) {
                $files[] = $path;
            } else {
                throw new IndexingFailedException('The specified file or directory "' . $path . '" does not exist!');
            }
        }

        return $files;
    }

    /**
     * @param string[] $files
     * @param string[] $excludedDirectories
     *
     * @return string[]
     */
    protected function getFilteredFilesToIndex(array $files, array $excludedDirectories)
    {
        $filteredItems = [];

        foreach ($files as $file) {
            $skipFile = false;

            foreach ($excludedDirectories as $excludedDirectory) {
                if (mb_strpos($file, $excludedDirectory) === 0) {
                    $skipFile = true;
                    break;
                }
            }

            if (!$skipFile) {
                $filteredItems[] = $file;
            }
        }

        return $filteredItems;
    }

    /**
     * Indexes builtin PHP structural elemens when necessary.
     */
    protected function indexBuiltinItemsIfNecessary()
    {
        $hasIndexedBuiltin = $this->storage->getSetting('has_indexed_builtin');

        if (!$hasIndexedBuiltin || !$hasIndexedBuiltin['value']) {
            $this->builtinIndexer->index();

            if ($hasIndexedBuiltin) {
                $this->storage->update(IndexStorageItemEnum::SETTINGS, $hasIndexedBuiltin['id'], [
                    'value' => 1
                ]);
            } else {
                $this->storage->insert(IndexStorageItemEnum::SETTINGS, [
                    'name'  => 'has_indexed_builtin',
                    'value' => 1
                ]);
            }
        }
    }

    /**
     * Prunes removed files from the index.
     */
    protected function pruneRemovedFiles()
    {
        $fileModifiedMap = $this->storage->getFileModifiedMap();

        foreach ($fileModifiedMap as $fileName => $indexedTime) {
            if (!file_exists($fileName)) {
                $this->logMessage('  - ' . $fileName);

                $this->storage->deleteFile($fileName);
            }
        }
    }
}
