<?php

namespace PhpIntegrator\Application\Command;

use PhpIntegrator\IndexedTest;

use PhpIntegrator\Indexing\IndexDatabase;

class LocalizeTypeTest extends IndexedTest
{
    public function testCorrectlyLocalizesVariousTypes()
    {
        $path = __DIR__ . '/LocalizeTypeTest/' . 'LocalizeType.php.test';

        $indexDatabase = $this->getDatabaseForTestFile($path);

        $command = new LocalizeType($this->getParser(), null, $indexDatabase);

        $this->assertEquals('\C', $command->localizeType('C', $path, 1));
        $this->assertEquals('\C', $command->localizeType('\C', $path, 5));
        $this->assertEquals('C', $command->localizeType('A\C', $path, 5));
        $this->assertEquals('C', $command->localizeType('B\C', $path, 10));
        $this->assertEquals('DateTime', $command->localizeType('B\DateTime', $path, 10));
        $this->assertEquals('DateTime', $command->localizeType('DateTime', $path, 11));
        $this->assertEquals('DateTime', $command->localizeType('DateTime', $path, 12));
        $this->assertEquals('DateTime', $command->localizeType('\DateTime', $path, 12));
        $this->assertEquals('D\Test', $command->localizeType('C\D\Test', $path, 13));
        $this->assertEquals('E', $command->localizeType('C\D\E', $path, 14));
        $this->assertEquals('H', $command->localizeType('F\G\H', $path, 16));
    }

    /**
     * @expectedException \UnexpectedValueException
     */
    public function testThrowsExceptionOnUnknownFile()
    {
        $command = new LocalizeType($this->getParser(), null, new IndexDatabase(':memory:', 1));

        $command->localizeType('C', 'MissingFile.php', 1);
    }
}
