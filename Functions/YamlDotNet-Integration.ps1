function Load-YamlDotNetLibraries([string] $dllPath) {
    #gci $dllPath | % { [Reflection.Assembly]::LoadFrom($_.FullName) } | Out-Null
	
	#one could go about this in two ways
	#1. load files into memory as a byte array and override assembly resolve and when it is one of these just use the ones in memory.
	# [system.appdomain]::CurrentDomain.AssemblyResolve
	#https://github.com/chucknorris/roundhouse/blob/master/product/roundhouse.databases.mysql/MySqlAdoNetProviderResolver.cs#L41
	
    # $dlls = gci $dllPath 
	# foreach ($dll in $dlls) {
		# $fileStream = ([System.IO.FileInfo] (Get-Item $dll.FullName)).OpenRead();
		# $assemblyBytes = new-object byte[] $fileStream.Length
		# $fileStream.Read($assemblyBytes, 0, $fileStream.Length);
		# $fileStream.Close();
		# [System.Reflection.Assembly]::Load($assemblyBytes);
	# }

	#2. shadow copy
	$dllTempPath = Join-Path $env:Temp (Join-Path 'poweryaml' 'assemblies')
	if (!(Test-Path($dllTempPath))) { [System.IO.Directory]::CreateDirectory($dllTempPath) }
	gci $dllPath | % { Copy-Item $_.FullName $dllTempPath} | Out-Null
    gci $dllTempPath | % { [Reflection.Assembly]::LoadFrom($_.FullName) } | Out-Null
	
}

function Get-YamlStream([string] $file) {
    $streamReader = [System.IO.File]::OpenText($file)
    $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream

    $yamlStream.Load([System.IO.TextReader] $streamReader)
    $streamReader.Close()
    return $yamlStream	
}

function Get-YamlDocument([string] $file) {
    $yamlStream = Get-YamlStream $file
    $document = $yamlStream.Documents[0]
    return $document
}

function Get-YamlDocumentFromString([string] $yamlString) {
    $stringReader = new-object System.IO.StringReader($yamlString)
    $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
    $yamlStream.Load([System.IO.TextReader] $stringReader)

    $document = $yamlStream.Documents[0]
    return $document
}

function Explode-Node($node) {
    if ($node.GetType().Name -eq "YamlScalarNode") {
        return Convert-YamlScalarNodeToValue $node 
    } elseif ($node.GetType().Name -eq "YamlMappingNode") {
        return Convert-YamlMappingNodeToHash $node
    } elseif ($node.GetType().Name -eq "YamlSequenceNode") {
        return Convert-YamlSequenceNodeToList $node
    }
}

function Convert-YamlScalarNodeToValue($node) {
    return Add-CastingFunctions($node.Value)
}

function Convert-YamlMappingNodeToHash($node) {
    $hash = @{}
    $yamlNodes = $node.Children

    foreach($key in $yamlNodes.Keys) {
        $hash[$key.Value] = Explode-Node $yamlNodes[$key]
    }

    return $hash
}

function Convert-YamlSequenceNodeToList($node) {
    $list = @()
    $yamlNodes = $node.Children

    foreach($yamlNode in $yamlNodes) {
        $list += Explode-Node $yamlNode
    }

    return $list
}

