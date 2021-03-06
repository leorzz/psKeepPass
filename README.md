<h2>This powershell module is a Wrapper around KeePassLib</h2>
<h3><a href="http://keepass.info/"><font color="#001ba0"><strong><font face="Segoe UI Semibold">KeePass</font></strong> - Official Site</font></a></h3>
<h2>CMDLETs</h2>
<table><colgroup><col /><col /></colgroup>
<tbody>
<tr><th>Command</th><th>Synopsis</th></tr>
<tr>
<td><a href="https://pskeepass.codeplex.com/wikipage?title=Get-KPEntry" target="_blank">Get-KPEntry</a></td>
<td>Ge t one or more fields of a database KeePass.</td>
</tr>
<tr>
<td><a href="https://pskeepass.codeplex.com/wikipage?title=Get-KPSecurePassword" target="_blank">Get-KPSecurePassword</a></td>
<td>Get a MastePass&nbsp;as a SecurePassword that can be used in parameters that is requested.</td>
</tr>
<tr>
<td><a href="https://pskeepass.codeplex.com/wikipage?title=New-KPEntry" target="_blank">New-KPEntry</a></td>
<td>Ad ds a new KeePass entry.</td>
</tr>
<tr>
<td><a href="https://pskeepass.codeplex.com/wikipage?title=New-KPSecurePassword" target="_blank">New-KPSecurePassword</a></td>
<td>Create a a MastePassword as a Secur ePassword that can be used in parameters that a password is requested.</td>
</tr>
<tr>
<td><a href="https://pskeepass.codeplex.com/wikipage?title=Remove-KPEntry" target="_blank">Remove-KPEntry</a></td>
<td>Remove a KeePass entry.</td>
</tr>
<tr>
<td><a href="https://pskeepass.codeplex.com/wikipage?title=Remove-KPSecurePassword" target="_blank">Remove-KPSecurePassword</a></td>
<td>Remove a MastePassword as a S ecurePassword.</td>
</tr>
<tr>
<td><a href="https://pskeepass.codeplex.com/wikipage?title=Set-KPEntry" target="_blank">Set-KPEntry</a></td>
<td>Change a KeePass entry.</td>
</tr>
</tbody>
</table>
<p>&nbsp;</p>
<p>If you have a version that is less than 3, then you need to update your PowerShell. To update to version 3 or more, you must download the Windows Management Framework 3:&nbsp;<a style="text-decoration: none; color: #0071c5;" href="http://www.microsoft.com/en-us/download/details.aspx?id=34595" rel="nofollow">http://www.microsoft.com/en-us/download/details.aspx?id=34595</a>&nbsp;or 5 <a title="https://www.microsoft.com/en-us/download/details.aspx?id=50395" href="https://www.microsoft.com/en-us/download/details.aspx?id=50395"> https://www.microsoft.com/en-us/download/details.aspx?id=50395</a>, then choose either the x86 or the x64 files depending on your system. For x64.</p>
<p>Allow PowerShell to import or use scripts including modules by running the following command:</p>
<ul>
<li>set-executionpolicy remotesigned</li>
</ul>
<p>Install PsGet by executing the following commands:(Skip this if you get WMF 5)</p>
<ul>
<li>(new-object Net.WebClient).DownloadString("<a style="text-decoration: none; color: #0071c5;" href="http://psget.net/GetPsGet.ps1" rel="nofollow">http://psget.net/GetPsGet.ps1</a>") | iex</li>
<li>import-module PsGet</li>
</ul>
<p>&nbsp;</p>
<h3>Inspect</h3>
<div>
<p><code>PS&gt; Save-Module -Name psKeePass -Path &lt;path&gt; </code></p>
</div>
<h3>Install</h3>
<div>
<p><code>PS&gt; Install-Module -Name psKeePass</code></p>
<h3>Update</h3>
<div>
<p><code>PS&gt; Update-Module -Name psKeePass</code></p>
<p><code>&nbsp;</code></p>
</div>
<p>&nbsp;</p>
</div>
<p><a title="https://www.powershellgallery.com/packages/psKeePass" href="https://www.powershellgallery.com/packages/psKeePass" target="_blank">https://www.powershellgallery.com/packages/psKeePass</a></p>
<p>&nbsp;</p>
