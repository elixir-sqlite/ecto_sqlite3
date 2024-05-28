Benchmark

Benchmark run from 2024-05-04 10:39:52.658755Z UTC

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



__Input: Big 1 Million__

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
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">1.90</td>
    <td style="white-space: nowrap; text-align: right">526.95 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;7.52%</td>
    <td style="white-space: nowrap; text-align: right">520.79 ms</td>
    <td style="white-space: nowrap; text-align: right">590.85 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">1.89</td>
    <td style="white-space: nowrap; text-align: right">527.72 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;7.17%</td>
    <td style="white-space: nowrap; text-align: right">523.29 ms</td>
    <td style="white-space: nowrap; text-align: right">589.90 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">1.89</td>
    <td style="white-space: nowrap; text-align: right">529.12 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;7.67%</td>
    <td style="white-space: nowrap; text-align: right">522.49 ms</td>
    <td style="white-space: nowrap; text-align: right">594.22 ms</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap;text-align: right">1.90</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">1.89</td>
    <td style="white-space: nowrap; text-align: right">1.0x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">1.89</td>
    <td style="white-space: nowrap; text-align: right">1.0x</td>
  </tr>

</table>




__Input: Date attr__

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
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">26.37</td>
    <td style="white-space: nowrap; text-align: right">37.93 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;7.64%</td>
    <td style="white-space: nowrap; text-align: right">37.53 ms</td>
    <td style="white-space: nowrap; text-align: right">48.13 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">25.98</td>
    <td style="white-space: nowrap; text-align: right">38.49 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;7.63%</td>
    <td style="white-space: nowrap; text-align: right">38.31 ms</td>
    <td style="white-space: nowrap; text-align: right">48.20 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">25.91</td>
    <td style="white-space: nowrap; text-align: right">38.59 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;7.51%</td>
    <td style="white-space: nowrap; text-align: right">38.46 ms</td>
    <td style="white-space: nowrap; text-align: right">48.29 ms</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap;text-align: right">26.37</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">25.98</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">25.91</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

</table>




__Input: Medium 100 Thousand__

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
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">26.27</td>
    <td style="white-space: nowrap; text-align: right">38.07 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;5.01%</td>
    <td style="white-space: nowrap; text-align: right">38.36 ms</td>
    <td style="white-space: nowrap; text-align: right">42.73 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">25.64</td>
    <td style="white-space: nowrap; text-align: right">39.01 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;5.25%</td>
    <td style="white-space: nowrap; text-align: right">39.42 ms</td>
    <td style="white-space: nowrap; text-align: right">43.28 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">25.44</td>
    <td style="white-space: nowrap; text-align: right">39.31 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;6.97%</td>
    <td style="white-space: nowrap; text-align: right">39.50 ms</td>
    <td style="white-space: nowrap; text-align: right">49.12 ms</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap;text-align: right">26.27</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">25.64</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">25.44</td>
    <td style="white-space: nowrap; text-align: right">1.03x</td>
  </tr>

</table>




__Input: Small 1 Thousand__

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
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">2.95 K</td>
    <td style="white-space: nowrap; text-align: right">339.32 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;13.05%</td>
    <td style="white-space: nowrap; text-align: right">330.33 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">493.99 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">2.92 K</td>
    <td style="white-space: nowrap; text-align: right">342.75 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;13.24%</td>
    <td style="white-space: nowrap; text-align: right">332.17 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">499.14 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">2.91 K</td>
    <td style="white-space: nowrap; text-align: right">343.63 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;12.64%</td>
    <td style="white-space: nowrap; text-align: right">330.21 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">495.04 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap;text-align: right">2.95 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">2.92 K</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">2.91 K</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

</table>




__Input: Time attr__

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
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">21.75</td>
    <td style="white-space: nowrap; text-align: right">45.98 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;11.17%</td>
    <td style="white-space: nowrap; text-align: right">45.25 ms</td>
    <td style="white-space: nowrap; text-align: right">61.90 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">21.43</td>
    <td style="white-space: nowrap; text-align: right">46.67 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;10.90%</td>
    <td style="white-space: nowrap; text-align: right">45.76 ms</td>
    <td style="white-space: nowrap; text-align: right">61.66 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">20.72</td>
    <td style="white-space: nowrap; text-align: right">48.26 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;9.03%</td>
    <td style="white-space: nowrap; text-align: right">48.63 ms</td>
    <td style="white-space: nowrap; text-align: right">62.19 ms</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap;text-align: right">21.75</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">21.43</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">20.72</td>
    <td style="white-space: nowrap; text-align: right">1.05x</td>
  </tr>

</table>




__Input: UUID attr__

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
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">23.23</td>
    <td style="white-space: nowrap; text-align: right">43.06 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;8.19%</td>
    <td style="white-space: nowrap; text-align: right">41.64 ms</td>
    <td style="white-space: nowrap; text-align: right">51.14 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">15.19</td>
    <td style="white-space: nowrap; text-align: right">65.81 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;7.56%</td>
    <td style="white-space: nowrap; text-align: right">63.25 ms</td>
    <td style="white-space: nowrap; text-align: right">76.27 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">14.89</td>
    <td style="white-space: nowrap; text-align: right">67.14 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;7.74%</td>
    <td style="white-space: nowrap; text-align: right">64.12 ms</td>
    <td style="white-space: nowrap; text-align: right">80.65 ms</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap;text-align: right">23.23</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">15.19</td>
    <td style="white-space: nowrap; text-align: right">1.53x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">14.89</td>
    <td style="white-space: nowrap; text-align: right">1.56x</td>
  </tr>

</table>