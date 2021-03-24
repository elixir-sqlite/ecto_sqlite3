
# Benchmark

Benchmark run from 2021-03-24 01:58:24.995583Z UTC

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
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">0.35</td>
    <td style="white-space: nowrap; text-align: right">2.82 s</td>
    <td style="white-space: nowrap; text-align: right">±15.78%</td>
    <td style="white-space: nowrap; text-align: right">2.82 s</td>
    <td style="white-space: nowrap; text-align: right">3.13 s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">0.34</td>
    <td style="white-space: nowrap; text-align: right">2.92 s</td>
    <td style="white-space: nowrap; text-align: right">±17.97%</td>
    <td style="white-space: nowrap; text-align: right">2.92 s</td>
    <td style="white-space: nowrap; text-align: right">3.29 s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">0.33</td>
    <td style="white-space: nowrap; text-align: right">2.99 s</td>
    <td style="white-space: nowrap; text-align: right">±13.08%</td>
    <td style="white-space: nowrap; text-align: right">2.99 s</td>
    <td style="white-space: nowrap; text-align: right">3.26 s</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap;text-align: right">0.35</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">0.34</td>
    <td style="white-space: nowrap; text-align: right">1.04x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">0.33</td>
    <td style="white-space: nowrap; text-align: right">1.06x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">4.61</td>
    <td style="white-space: nowrap; text-align: right">217.08 ms</td>
    <td style="white-space: nowrap; text-align: right">±13.97%</td>
    <td style="white-space: nowrap; text-align: right">214.42 ms</td>
    <td style="white-space: nowrap; text-align: right">271.56 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">4.56</td>
    <td style="white-space: nowrap; text-align: right">219.25 ms</td>
    <td style="white-space: nowrap; text-align: right">±18.19%</td>
    <td style="white-space: nowrap; text-align: right">210.43 ms</td>
    <td style="white-space: nowrap; text-align: right">300.02 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">4.49</td>
    <td style="white-space: nowrap; text-align: right">222.95 ms</td>
    <td style="white-space: nowrap; text-align: right">±15.03%</td>
    <td style="white-space: nowrap; text-align: right">232.42 ms</td>
    <td style="white-space: nowrap; text-align: right">266.39 ms</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap;text-align: right">4.61</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">4.56</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">4.49</td>
    <td style="white-space: nowrap; text-align: right">1.03x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap; text-align: right">4.53</td>
    <td style="white-space: nowrap; text-align: right">220.75 ms</td>
    <td style="white-space: nowrap; text-align: right">±15.57%</td>
    <td style="white-space: nowrap; text-align: right">209.17 ms</td>
    <td style="white-space: nowrap; text-align: right">287.22 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">4.40</td>
    <td style="white-space: nowrap; text-align: right">227.35 ms</td>
    <td style="white-space: nowrap; text-align: right">±16.30%</td>
    <td style="white-space: nowrap; text-align: right">222.39 ms</td>
    <td style="white-space: nowrap; text-align: right">335.90 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">4.35</td>
    <td style="white-space: nowrap; text-align: right">230.09 ms</td>
    <td style="white-space: nowrap; text-align: right">±19.61%</td>
    <td style="white-space: nowrap; text-align: right">236.94 ms</td>
    <td style="white-space: nowrap; text-align: right">309.96 ms</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap;text-align: right">4.53</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">4.40</td>
    <td style="white-space: nowrap; text-align: right">1.03x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">4.35</td>
    <td style="white-space: nowrap; text-align: right">1.04x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">883.24</td>
    <td style="white-space: nowrap; text-align: right">1.13 ms</td>
    <td style="white-space: nowrap; text-align: right">±62.88%</td>
    <td style="white-space: nowrap; text-align: right">0.93 ms</td>
    <td style="white-space: nowrap; text-align: right">2.71 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">873.53</td>
    <td style="white-space: nowrap; text-align: right">1.14 ms</td>
    <td style="white-space: nowrap; text-align: right">±60.06%</td>
    <td style="white-space: nowrap; text-align: right">0.92 ms</td>
    <td style="white-space: nowrap; text-align: right">2.90 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">862.33</td>
    <td style="white-space: nowrap; text-align: right">1.16 ms</td>
    <td style="white-space: nowrap; text-align: right">±62.27%</td>
    <td style="white-space: nowrap; text-align: right">0.92 ms</td>
    <td style="white-space: nowrap; text-align: right">2.77 ms</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap;text-align: right">883.24</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">873.53</td>
    <td style="white-space: nowrap; text-align: right">1.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">862.33</td>
    <td style="white-space: nowrap; text-align: right">1.02x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap; text-align: right">3.40</td>
    <td style="white-space: nowrap; text-align: right">294.30 ms</td>
    <td style="white-space: nowrap; text-align: right">±15.60%</td>
    <td style="white-space: nowrap; text-align: right">281.23 ms</td>
    <td style="white-space: nowrap; text-align: right">367.65 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">3.18</td>
    <td style="white-space: nowrap; text-align: right">314.55 ms</td>
    <td style="white-space: nowrap; text-align: right">±17.11%</td>
    <td style="white-space: nowrap; text-align: right">313.35 ms</td>
    <td style="white-space: nowrap; text-align: right">415.89 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">3.03</td>
    <td style="white-space: nowrap; text-align: right">329.99 ms</td>
    <td style="white-space: nowrap; text-align: right">±16.46%</td>
    <td style="white-space: nowrap; text-align: right">321.68 ms</td>
    <td style="white-space: nowrap; text-align: right">457.42 ms</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap;text-align: right">3.40</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">3.18</td>
    <td style="white-space: nowrap; text-align: right">1.07x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">3.03</td>
    <td style="white-space: nowrap; text-align: right">1.12x</td>
  </tr>

</table>



<hr/>


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
    <td style="white-space: nowrap; text-align: right">3.61</td>
    <td style="white-space: nowrap; text-align: right">277.20 ms</td>
    <td style="white-space: nowrap; text-align: right">±16.59%</td>
    <td style="white-space: nowrap; text-align: right">266.05 ms</td>
    <td style="white-space: nowrap; text-align: right">372.08 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">2.75</td>
    <td style="white-space: nowrap; text-align: right">363.06 ms</td>
    <td style="white-space: nowrap; text-align: right">±14.14%</td>
    <td style="white-space: nowrap; text-align: right">382.70 ms</td>
    <td style="white-space: nowrap; text-align: right">437.37 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">2.73</td>
    <td style="white-space: nowrap; text-align: right">365.91 ms</td>
    <td style="white-space: nowrap; text-align: right">±19.81%</td>
    <td style="white-space: nowrap; text-align: right">367.23 ms</td>
    <td style="white-space: nowrap; text-align: right">515.29 ms</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">SQLite3 Loader</td>
    <td style="white-space: nowrap;text-align: right">3.61</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">Pg Loader</td>
    <td style="white-space: nowrap; text-align: right">2.75</td>
    <td style="white-space: nowrap; text-align: right">1.31x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">MyXQL Loader</td>
    <td style="white-space: nowrap; text-align: right">2.73</td>
    <td style="white-space: nowrap; text-align: right">1.32x</td>
  </tr>

</table>



<hr/>

