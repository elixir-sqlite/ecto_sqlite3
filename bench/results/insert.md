
# Benchmark

Benchmark run from 2021-03-24 02:05:58.706995Z UTC

## System

Benchmark suite executing on the following system:

<table style="width: 1%">
  <tr>
    <th style="width: 1%; white-space: nowrap">Operating System</th>
    <td>Linux</td>
  </tr><tr>
    <th style="white-space: nowrap">CPU Information</th>
    <td style="white-space: nowrap">AMD Ryzen 7 PRO 4750U with Radeon Graphics</td>
  </tr><tr>
    <th style="white-space: nowrap">Number of Available Cores</th>
    <td style="white-space: nowrap">16</td>
  </tr><tr>
    <th style="white-space: nowrap">Available Memory</th>
    <td style="white-space: nowrap">14.92 GB</td>
  </tr><tr>
    <th style="white-space: nowrap">Elixir Version</th>
    <td style="white-space: nowrap">1.11.3</td>
  </tr><tr>
    <th style="white-space: nowrap">Erlang Version</th>
    <td style="white-space: nowrap">23.2.6</td>
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
    <td style="white-space: nowrap; text-align: right">7218.07</td>
    <td style="white-space: nowrap; text-align: right">0.139 ms</td>
    <td style="white-space: nowrap; text-align: right">±43.60%</td>
    <td style="white-space: nowrap; text-align: right">0.123 ms</td>
    <td style="white-space: nowrap; text-align: right">0.37 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Insert</td>
    <td style="white-space: nowrap; text-align: right">421.57</td>
    <td style="white-space: nowrap; text-align: right">2.37 ms</td>
    <td style="white-space: nowrap; text-align: right">±12.13%</td>
    <td style="white-space: nowrap; text-align: right">2.37 ms</td>
    <td style="white-space: nowrap; text-align: right">2.90 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Insert</td>
    <td style="white-space: nowrap; text-align: right">284.25</td>
    <td style="white-space: nowrap; text-align: right">3.52 ms</td>
    <td style="white-space: nowrap; text-align: right">±13.34%</td>
    <td style="white-space: nowrap; text-align: right">3.53 ms</td>
    <td style="white-space: nowrap; text-align: right">5.05 ms</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">SQLite3 Insert</td>
    <td style="white-space: nowrap;text-align: right">7218.07</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Insert</td>
    <td style="white-space: nowrap; text-align: right">421.57</td>
    <td style="white-space: nowrap; text-align: right">17.12x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Insert</td>
    <td style="white-space: nowrap; text-align: right">284.25</td>
    <td style="white-space: nowrap; text-align: right">25.39x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap; text-align: right">7765.76</td>
    <td style="white-space: nowrap; text-align: right">0.129 ms</td>
    <td style="white-space: nowrap; text-align: right">±32.88%</td>
    <td style="white-space: nowrap; text-align: right">0.122 ms</td>
    <td style="white-space: nowrap; text-align: right">0.28 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Insert</td>
    <td style="white-space: nowrap; text-align: right">422.86</td>
    <td style="white-space: nowrap; text-align: right">2.36 ms</td>
    <td style="white-space: nowrap; text-align: right">±10.49%</td>
    <td style="white-space: nowrap; text-align: right">2.36 ms</td>
    <td style="white-space: nowrap; text-align: right">3.02 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Insert</td>
    <td style="white-space: nowrap; text-align: right">274.00</td>
    <td style="white-space: nowrap; text-align: right">3.65 ms</td>
    <td style="white-space: nowrap; text-align: right">±38.43%</td>
    <td style="white-space: nowrap; text-align: right">3.59 ms</td>
    <td style="white-space: nowrap; text-align: right">4.75 ms</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">SQLite3 Insert</td>
    <td style="white-space: nowrap;text-align: right">7765.76</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Insert</td>
    <td style="white-space: nowrap; text-align: right">422.86</td>
    <td style="white-space: nowrap; text-align: right">18.37x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Insert</td>
    <td style="white-space: nowrap; text-align: right">274.00</td>
    <td style="white-space: nowrap; text-align: right">28.34x</td>
  </tr>

</table>



<hr/>

