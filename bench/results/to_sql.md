
# Benchmark

Benchmark run from 2021-03-24 02:02:16.278354Z UTC

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
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">105.28 K</td>
    <td style="white-space: nowrap; text-align: right">9.50 μs</td>
    <td style="white-space: nowrap; text-align: right">±116.92%</td>
    <td style="white-space: nowrap; text-align: right">8.66 μs</td>
    <td style="white-space: nowrap; text-align: right">24.79 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">96.97 K</td>
    <td style="white-space: nowrap; text-align: right">10.31 μs</td>
    <td style="white-space: nowrap; text-align: right">±220.90%</td>
    <td style="white-space: nowrap; text-align: right">8.66 μs</td>
    <td style="white-space: nowrap; text-align: right">26.75 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">90.46 K</td>
    <td style="white-space: nowrap; text-align: right">11.05 μs</td>
    <td style="white-space: nowrap; text-align: right">±204.34%</td>
    <td style="white-space: nowrap; text-align: right">8.66 μs</td>
    <td style="white-space: nowrap; text-align: right">39.53 μs</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap;text-align: right">105.28 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">96.97 K</td>
    <td style="white-space: nowrap; text-align: right">1.09x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">90.46 K</td>
    <td style="white-space: nowrap; text-align: right">1.16x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">100.25 K</td>
    <td style="white-space: nowrap; text-align: right">9.97 μs</td>
    <td style="white-space: nowrap; text-align: right">±92.25%</td>
    <td style="white-space: nowrap; text-align: right">9.15 μs</td>
    <td style="white-space: nowrap; text-align: right">23.68 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">98.47 K</td>
    <td style="white-space: nowrap; text-align: right">10.16 μs</td>
    <td style="white-space: nowrap; text-align: right">±88.64%</td>
    <td style="white-space: nowrap; text-align: right">9.22 μs</td>
    <td style="white-space: nowrap; text-align: right">28.70 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">90.40 K</td>
    <td style="white-space: nowrap; text-align: right">11.06 μs</td>
    <td style="white-space: nowrap; text-align: right">±117.48%</td>
    <td style="white-space: nowrap; text-align: right">9.22 μs</td>
    <td style="white-space: nowrap; text-align: right">38.69 μs</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap;text-align: right">100.25 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">98.47 K</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">90.40 K</td>
    <td style="white-space: nowrap; text-align: right">1.11x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">173.31 K</td>
    <td style="white-space: nowrap; text-align: right">5.77 μs</td>
    <td style="white-space: nowrap; text-align: right">±389.85%</td>
    <td style="white-space: nowrap; text-align: right">4.47 μs</td>
    <td style="white-space: nowrap; text-align: right">20.18 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">173.06 K</td>
    <td style="white-space: nowrap; text-align: right">5.78 μs</td>
    <td style="white-space: nowrap; text-align: right">±411.02%</td>
    <td style="white-space: nowrap; text-align: right">4.82 μs</td>
    <td style="white-space: nowrap; text-align: right">16.20 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">167.17 K</td>
    <td style="white-space: nowrap; text-align: right">5.98 μs</td>
    <td style="white-space: nowrap; text-align: right">±420.59%</td>
    <td style="white-space: nowrap; text-align: right">4.82 μs</td>
    <td style="white-space: nowrap; text-align: right">19.42 μs</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap;text-align: right">173.31 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">173.06 K</td>
    <td style="white-space: nowrap; text-align: right">1.0x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">167.17 K</td>
    <td style="white-space: nowrap; text-align: right">1.04x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">177.36 K</td>
    <td style="white-space: nowrap; text-align: right">5.64 μs</td>
    <td style="white-space: nowrap; text-align: right">±446.37%</td>
    <td style="white-space: nowrap; text-align: right">4.47 μs</td>
    <td style="white-space: nowrap; text-align: right">17.67 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">169.74 K</td>
    <td style="white-space: nowrap; text-align: right">5.89 μs</td>
    <td style="white-space: nowrap; text-align: right">±394.73%</td>
    <td style="white-space: nowrap; text-align: right">4.82 μs</td>
    <td style="white-space: nowrap; text-align: right">18.16 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">162.83 K</td>
    <td style="white-space: nowrap; text-align: right">6.14 μs</td>
    <td style="white-space: nowrap; text-align: right">±383.32%</td>
    <td style="white-space: nowrap; text-align: right">4.82 μs</td>
    <td style="white-space: nowrap; text-align: right">22.14 μs</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap;text-align: right">177.36 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">169.74 K</td>
    <td style="white-space: nowrap; text-align: right">1.04x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">162.83 K</td>
    <td style="white-space: nowrap; text-align: right">1.09x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">335.81 K</td>
    <td style="white-space: nowrap; text-align: right">2.98 μs</td>
    <td style="white-space: nowrap; text-align: right">±775.40%</td>
    <td style="white-space: nowrap; text-align: right">2.03 μs</td>
    <td style="white-space: nowrap; text-align: right">9.43 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">325.92 K</td>
    <td style="white-space: nowrap; text-align: right">3.07 μs</td>
    <td style="white-space: nowrap; text-align: right">±948.36%</td>
    <td style="white-space: nowrap; text-align: right">2.02 μs</td>
    <td style="white-space: nowrap; text-align: right">8.31 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">301.67 K</td>
    <td style="white-space: nowrap; text-align: right">3.31 μs</td>
    <td style="white-space: nowrap; text-align: right">±832.06%</td>
    <td style="white-space: nowrap; text-align: right">2.03 μs</td>
    <td style="white-space: nowrap; text-align: right">11.59 μs</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap;text-align: right">335.81 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">325.92 K</td>
    <td style="white-space: nowrap; text-align: right">1.03x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">301.67 K</td>
    <td style="white-space: nowrap; text-align: right">1.11x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">186.48 K</td>
    <td style="white-space: nowrap; text-align: right">5.36 μs</td>
    <td style="white-space: nowrap; text-align: right">±400.39%</td>
    <td style="white-space: nowrap; text-align: right">4.40 μs</td>
    <td style="white-space: nowrap; text-align: right">17.81 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">182.02 K</td>
    <td style="white-space: nowrap; text-align: right">5.49 μs</td>
    <td style="white-space: nowrap; text-align: right">±402.64%</td>
    <td style="white-space: nowrap; text-align: right">4.40 μs</td>
    <td style="white-space: nowrap; text-align: right">17.39 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">172.19 K</td>
    <td style="white-space: nowrap; text-align: right">5.81 μs</td>
    <td style="white-space: nowrap; text-align: right">±427.38%</td>
    <td style="white-space: nowrap; text-align: right">4.47 μs</td>
    <td style="white-space: nowrap; text-align: right">21.44 μs</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap;text-align: right">186.48 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">182.02 K</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">172.19 K</td>
    <td style="white-space: nowrap; text-align: right">1.08x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">200.19 K</td>
    <td style="white-space: nowrap; text-align: right">5.00 μs</td>
    <td style="white-space: nowrap; text-align: right">±657.77%</td>
    <td style="white-space: nowrap; text-align: right">3.49 μs</td>
    <td style="white-space: nowrap; text-align: right">14.88 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">199.77 K</td>
    <td style="white-space: nowrap; text-align: right">5.01 μs</td>
    <td style="white-space: nowrap; text-align: right">±698.35%</td>
    <td style="white-space: nowrap; text-align: right">3.49 μs</td>
    <td style="white-space: nowrap; text-align: right">13.90 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">191.70 K</td>
    <td style="white-space: nowrap; text-align: right">5.22 μs</td>
    <td style="white-space: nowrap; text-align: right">±601.95%</td>
    <td style="white-space: nowrap; text-align: right">3.56 μs</td>
    <td style="white-space: nowrap; text-align: right">16.06 μs</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap;text-align: right">200.19 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">199.77 K</td>
    <td style="white-space: nowrap; text-align: right">1.0x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">191.70 K</td>
    <td style="white-space: nowrap; text-align: right">1.04x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">263.35 K</td>
    <td style="white-space: nowrap; text-align: right">3.80 μs</td>
    <td style="white-space: nowrap; text-align: right">±1304.70%</td>
    <td style="white-space: nowrap; text-align: right">2.86 μs</td>
    <td style="white-space: nowrap; text-align: right">10.13 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">260.96 K</td>
    <td style="white-space: nowrap; text-align: right">3.83 μs</td>
    <td style="white-space: nowrap; text-align: right">±760.59%</td>
    <td style="white-space: nowrap; text-align: right">2.86 μs</td>
    <td style="white-space: nowrap; text-align: right">10.20 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">249.05 K</td>
    <td style="white-space: nowrap; text-align: right">4.02 μs</td>
    <td style="white-space: nowrap; text-align: right">±827.04%</td>
    <td style="white-space: nowrap; text-align: right">2.86 μs</td>
    <td style="white-space: nowrap; text-align: right">12.99 μs</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap;text-align: right">263.35 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap; text-align: right">260.96 K</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">249.05 K</td>
    <td style="white-space: nowrap; text-align: right">1.06x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap; text-align: right">162.26 K</td>
    <td style="white-space: nowrap; text-align: right">6.16 μs</td>
    <td style="white-space: nowrap; text-align: right">±343.86%</td>
    <td style="white-space: nowrap; text-align: right">5.31 μs</td>
    <td style="white-space: nowrap; text-align: right">17.74 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">159.31 K</td>
    <td style="white-space: nowrap; text-align: right">6.28 μs</td>
    <td style="white-space: nowrap; text-align: right">±305.50%</td>
    <td style="white-space: nowrap; text-align: right">5.38 μs</td>
    <td style="white-space: nowrap; text-align: right">19.35 μs</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">154.28 K</td>
    <td style="white-space: nowrap; text-align: right">6.48 μs</td>
    <td style="white-space: nowrap; text-align: right">±355.38%</td>
    <td style="white-space: nowrap; text-align: right">5.45 μs</td>
    <td style="white-space: nowrap; text-align: right">20.04 μs</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Query Builder</td>
    <td style="white-space: nowrap;text-align: right">162.26 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Query Builder</td>
    <td style="white-space: nowrap; text-align: right">159.31 K</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Query Builder</td>
    <td style="white-space: nowrap; text-align: right">154.28 K</td>
    <td style="white-space: nowrap; text-align: right">1.05x</td>
  </tr>

</table>



<hr/>

