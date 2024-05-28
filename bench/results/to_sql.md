Benchmark

Benchmark run from 2024-05-04 10:48:53.108179Z UTC

## System

Benchmark suite executing on the following system:

<table style="width: 1%">
  <tr>
    <th style="width: 1%; white-space: nowrap">Operating System</th>
    <td>macOS</td>
  </tr><tr>
    <th style="white-space: nowrap">CPU Information</th>
    <td style="white-space: nowrap">Apple M3 Max</td>
  </tr><tr>
    <th style="white-space: nowrap">Number of Available Cores</th>
    <td style="white-space: nowrap">16</td>
  </tr><tr>
    <th style="white-space: nowrap">Available Memory</th>
    <td style="white-space: nowrap">128 GB</td>
  </tr><tr>
    <th style="white-space: nowrap">Elixir Version</th>
    <td style="white-space: nowrap">1.16.2</td>
  </tr><tr>
    <th style="white-space: nowrap">Erlang Version</th>
    <td style="white-space: nowrap">26.2.4</td>
  </tr>
</table>

## Configuration

Benchmark suite executing with the following configuration:

<table style="width: 1%">
  <tr>
    <th style="width: 1%">:time</th>
    <td style="white-space: nowrap">5 s</td>
  </tr><tr>
    <th>:parallel</th>
    <td style="white-space: nowrap">1</td>
  </tr><tr>
    <th>:warmup</th>
    <td style="white-space: nowrap">2 s</td>
  </tr>
</table>

## Statistics



__Input: Complex Query 2 Joins__

Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">382.74 K</td>
    <td style="white-space: nowrap; text-align: right">2.61 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;374.25%</td>
    <td style="white-space: nowrap; text-align: right">2.38 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">3.42 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">374.17 K</td>
    <td style="white-space: nowrap; text-align: right">2.67 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;382.43%</td>
    <td style="white-space: nowrap; text-align: right">2.46 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">3.42 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">360.95 K</td>
    <td style="white-space: nowrap; text-align: right">2.77 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;360.52%</td>
    <td style="white-space: nowrap; text-align: right">2.54 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">3.58 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap;text-align: right">382.74 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">374.17 K</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">360.95 K</td>
    <td style="white-space: nowrap; text-align: right">1.06x</td>
  </tr>

</table>




__Input: Complex Query 4 Joins__

Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">342.45 K</td>
    <td style="white-space: nowrap; text-align: right">2.92 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;313.75%</td>
    <td style="white-space: nowrap; text-align: right">2.67 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">4.08 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">340.76 K</td>
    <td style="white-space: nowrap; text-align: right">2.93 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;350.68%</td>
    <td style="white-space: nowrap; text-align: right">2.71 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">3.88 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">336.08 K</td>
    <td style="white-space: nowrap; text-align: right">2.98 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;328.89%</td>
    <td style="white-space: nowrap; text-align: right">2.79 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">3.88 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap;text-align: right">342.45 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">340.76 K</td>
    <td style="white-space: nowrap; text-align: right">1.0x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">336.08 K</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

</table>




__Input: Fetch First Registry__

Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">752.12 K</td>
    <td style="white-space: nowrap; text-align: right">1.33 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;868.39%</td>
    <td style="white-space: nowrap; text-align: right">1.17 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.63 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">721.56 K</td>
    <td style="white-space: nowrap; text-align: right">1.39 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;820.83%</td>
    <td style="white-space: nowrap; text-align: right">1.25 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.67 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">703.84 K</td>
    <td style="white-space: nowrap; text-align: right">1.42 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;817.39%</td>
    <td style="white-space: nowrap; text-align: right">1.29 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.71 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap;text-align: right">752.12 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">721.56 K</td>
    <td style="white-space: nowrap; text-align: right">1.04x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">703.84 K</td>
    <td style="white-space: nowrap; text-align: right">1.07x</td>
  </tr>

</table>




__Input: Fetch Last Registry__

Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">731.59 K</td>
    <td style="white-space: nowrap; text-align: right">1.37 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;795.20%</td>
    <td style="white-space: nowrap; text-align: right">1.21 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.71 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">716.25 K</td>
    <td style="white-space: nowrap; text-align: right">1.40 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;814.43%</td>
    <td style="white-space: nowrap; text-align: right">1.25 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.67 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">707.98 K</td>
    <td style="white-space: nowrap; text-align: right">1.41 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;839.02%</td>
    <td style="white-space: nowrap; text-align: right">1.25 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.67 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap;text-align: right">731.59 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">716.25 K</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">707.98 K</td>
    <td style="white-space: nowrap; text-align: right">1.03x</td>
  </tr>

</table>




__Input: Ordinary Delete All__

Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">1.34 M</td>
    <td style="white-space: nowrap; text-align: right">747.69 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;2442.90%</td>
    <td style="white-space: nowrap; text-align: right">666 ns</td>
    <td style="white-space: nowrap; text-align: right">917 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">1.32 M</td>
    <td style="white-space: nowrap; text-align: right">758.40 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;2490.71%</td>
    <td style="white-space: nowrap; text-align: right">667 ns</td>
    <td style="white-space: nowrap; text-align: right">875 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">1.31 M</td>
    <td style="white-space: nowrap; text-align: right">762.71 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;2451.66%</td>
    <td style="white-space: nowrap; text-align: right">667 ns</td>
    <td style="white-space: nowrap; text-align: right">875 ns</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap;text-align: right">1.34 M</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">1.32 M</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">1.31 M</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

</table>




__Input: Ordinary Order By__

Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">742.88 K</td>
    <td style="white-space: nowrap; text-align: right">1.35 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;918.40%</td>
    <td style="white-space: nowrap; text-align: right">1.17 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.67 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">729.59 K</td>
    <td style="white-space: nowrap; text-align: right">1.37 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;913.47%</td>
    <td style="white-space: nowrap; text-align: right">1.21 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.58 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">721.11 K</td>
    <td style="white-space: nowrap; text-align: right">1.39 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;918.31%</td>
    <td style="white-space: nowrap; text-align: right">1.21 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.58 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap;text-align: right">742.88 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">729.59 K</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">721.11 K</td>
    <td style="white-space: nowrap; text-align: right">1.03x</td>
  </tr>

</table>




__Input: Ordinary Select All__

Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">838.25 K</td>
    <td style="white-space: nowrap; text-align: right">1.19 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1122.54%</td>
    <td style="white-space: nowrap; text-align: right">1.04 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.46 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">822.53 K</td>
    <td style="white-space: nowrap; text-align: right">1.22 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1179.00%</td>
    <td style="white-space: nowrap; text-align: right">1.08 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.38 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">809.74 K</td>
    <td style="white-space: nowrap; text-align: right">1.23 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1198.22%</td>
    <td style="white-space: nowrap; text-align: right">1.08 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1.42 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap;text-align: right">838.25 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">822.53 K</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">809.74 K</td>
    <td style="white-space: nowrap; text-align: right">1.04x</td>
  </tr>

</table>




__Input: Ordinary Update All__

Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">1.03 M</td>
    <td style="white-space: nowrap; text-align: right">971.15 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1801.37%</td>
    <td style="white-space: nowrap; text-align: right">834 ns</td>
    <td style="white-space: nowrap; text-align: right">1167 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">1.01 M</td>
    <td style="white-space: nowrap; text-align: right">990.87 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1533.42%</td>
    <td style="white-space: nowrap; text-align: right">875 ns</td>
    <td style="white-space: nowrap; text-align: right">1125 ns</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">1.00 M</td>
    <td style="white-space: nowrap; text-align: right">999.05 ns</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1416.75%</td>
    <td style="white-space: nowrap; text-align: right">875 ns</td>
    <td style="white-space: nowrap; text-align: right">1166 ns</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap;text-align: right">1.03 M</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">1.01 M</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">1.00 M</td>
    <td style="white-space: nowrap; text-align: right">1.03x</td>
  </tr>

</table>




__Input: Ordinary Where__

Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">579.57 K</td>
    <td style="white-space: nowrap; text-align: right">1.73 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;668.48%</td>
    <td style="white-space: nowrap; text-align: right">1.54 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">2.17 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">574.41 K</td>
    <td style="white-space: nowrap; text-align: right">1.74 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;631.02%</td>
    <td style="white-space: nowrap; text-align: right">1.58 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">2.13 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">568.60 K</td>
    <td style="white-space: nowrap; text-align: right">1.76 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;635.93%</td>
    <td style="white-space: nowrap; text-align: right">1.62 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">2.13 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap;text-align: right">579.57 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">574.41 K</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">568.60 K</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

</table>