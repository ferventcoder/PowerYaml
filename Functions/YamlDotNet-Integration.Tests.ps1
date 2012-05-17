$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Casting.ps1"
. "$here\YamlDotNet-Integration.ps1"
Load-YamlDotNetLibraries "$here\..\Libs"

Describe "Load-YamlDotNetLibraries" {

	$yamldotNet = "$here\..\Libs\YamlDotNet.Core.dll"
    $yamldotNetTempName = "$here\..\Libs\YamlDotNet.Core.Temp.dll"
	
    It "should not lock the assembly files" {
		Copy-Item $yamldotNet  $yamldotNetTempName
		Remove-Item $yamldotNet
		Copy-Item $yamldotNetTempName $yamldotNet  -force
		Remove-Item $yamldotNetTempName
		$result = Test-Path $yamldotNet
		$result.should.be($true)
    }
}

Describe "Convert-YamlScalarNodeToValue" {

    It "takes a YamlScalar and converts it to a value type" {

        $node = New-Object YamlDotNet.RepresentationModel.YamlScalarNode 5
        $result = Convert-YamlScalarNodeToValue $node

        $result.should.be(5)
    }
}

Describe "Convert-YamlSequenceNodeToList" {

    It "taks a YamlSequence and converts it to an array" {
        $yaml = Get-YamlDocumentFromString "---`n- single item`n- second item"

        $result = Convert-YamlSequenceNodeToList $yaml.RootNode 
        $result.count.should.be(2)
    }

}

Describe "Convert-YamlMappingNodeToHash" {

    It "takes a YamlMappingNode and converts it to a hash" {
        $yaml = Get-YamlDocumentFromString "---`nkey1:   value1`nkey2:   value2"

        $result = Convert-YamlMappingNodeToHash $yaml.RootNode
        $result.keys.count.should.be(2)
    }

}

Describe "Get-YamlDocumentFromString" {

    It "will return a YamlDocument if given proper YAML" {
        $document = Get-YamlDocumentFromString "---"
        $document.GetType().Name.should.be("YamlDocument")
    }

}
