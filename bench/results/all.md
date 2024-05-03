Benchmark

Benchmark run from 2024-05-04 10:50:11.956493Z UTC

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
    <td style="white-space: nowrap">10 s</td>
  </tr><tr>
    <th>:parallel</th>
    <td style="white-space: nowrap">1</td>
  </tr><tr>
    <th>:warmup</th>
    <td style="white-space: nowrap">2 s</td>
  </tr>
</table>

## Statistics



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
    <td style="white-space: nowrap">MyXQL Repo.all/2</td>
    <td style="white-space: nowrap; text-align: right">639.68</td>
    <td style="white-space: nowrap; text-align: right">1.56 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;12.01%</td>
    <td style="white-space: nowrap; text-align: right">1.54 ms</td>
    <td style="white-space: nowrap; text-align: right">2.20 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Repo.all/2</td>
    <td style="white-space: nowrap; text-align: right">465.99</td>
    <td style="white-space: nowrap; text-align: right">2.15 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;4.82%</td>
    <td style="white-space: nowrap; text-align: right">2.13 ms</td>
    <td style="white-space: nowrap; text-align: right">2.43 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Repo.all/2</td>
    <td style="white-space: nowrap; text-align: right">214.16</td>
    <td style="white-space: nowrap; text-align: right">4.67 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;12.05%</td>
    <td style="white-space: nowrap; text-align: right">4.66 ms</td>
    <td style="white-space: nowrap; text-align: right">5.86 ms</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Repo.all/2</td>
    <td style="white-space: nowrap;text-align: right">639.68</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Repo.all/2</td>
    <td style="white-space: nowrap; text-align: right">465.99</td>
    <td style="white-space: nowrap; text-align: right">1.37x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Repo.all/2</td>
    <td style="white-space: nowrap; text-align: right">214.16</td>
    <td style="white-space: nowrap; text-align: right">2.99x</td>
  </tr>

</table>