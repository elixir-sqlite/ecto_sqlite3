Benchmark

Benchmark run from 2024-05-04 10:49:35.563150Z UTC

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



__Input: Changeset__

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
    <td style="white-space: nowrap">SQLite3 Insert</td>
    <td style="white-space: nowrap; text-align: right">26.72 K</td>
    <td style="white-space: nowrap; text-align: right">37.42 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;89.66%</td>
    <td style="white-space: nowrap; text-align: right">32.88 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">74.21 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Insert</td>
    <td style="white-space: nowrap; text-align: right">9.65 K</td>
    <td style="white-space: nowrap; text-align: right">103.63 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;68.38%</td>
    <td style="white-space: nowrap; text-align: right">102.75 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">177.39 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Insert</td>
    <td style="white-space: nowrap; text-align: right">5.49 K</td>
    <td style="white-space: nowrap; text-align: right">182.25 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;49.23%</td>
    <td style="white-space: nowrap; text-align: right">182.33 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">233.08 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">SQLite3 Insert</td>
    <td style="white-space: nowrap;text-align: right">26.72 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Insert</td>
    <td style="white-space: nowrap; text-align: right">9.65 K</td>
    <td style="white-space: nowrap; text-align: right">2.77x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Insert</td>
    <td style="white-space: nowrap; text-align: right">5.49 K</td>
    <td style="white-space: nowrap; text-align: right">4.87x</td>
  </tr>

</table>




__Input: Struct__

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
    <td style="white-space: nowrap">SQLite3 Insert</td>
    <td style="white-space: nowrap; text-align: right">26.71 K</td>
    <td style="white-space: nowrap; text-align: right">37.44 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;87.15%</td>
    <td style="white-space: nowrap; text-align: right">32.92 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">70.50 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Insert</td>
    <td style="white-space: nowrap; text-align: right">9.34 K</td>
    <td style="white-space: nowrap; text-align: right">107.08 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;13.80%</td>
    <td style="white-space: nowrap; text-align: right">106.87 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">132.46 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Insert</td>
    <td style="white-space: nowrap; text-align: right">5.67 K</td>
    <td style="white-space: nowrap; text-align: right">176.45 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;70.69%</td>
    <td style="white-space: nowrap; text-align: right">176.79 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">234.70 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">SQLite3 Insert</td>
    <td style="white-space: nowrap;text-align: right">26.71 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Insert</td>
    <td style="white-space: nowrap; text-align: right">9.34 K</td>
    <td style="white-space: nowrap; text-align: right">2.86x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Insert</td>
    <td style="white-space: nowrap; text-align: right">5.67 K</td>
    <td style="white-space: nowrap; text-align: right">4.71x</td>
  </tr>

</table>