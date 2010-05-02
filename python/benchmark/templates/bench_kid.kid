   <tbody>
    <tr py:for="i, item in enumerate(stocks)" class="${i % 2 == 1 and 'even' or 'odd'}">
     <td style="text-align: center" py:content="i + 1">n</td>
     <td>
      <a href="/stocks/${item['symbol']}" py:content="item['symbol']">item['symbol']</a>
     </td>
     <td>
      <a href="${item['url']}" py:content="item['name']">item['name']</a>
     </td>
     <td>
      <strong py:content="item['price']">item['price']</strong>
     </td>
<span py:if="item['change'] &lt; 0" py:strip="">
     <td class="minus" py:content="item['change']">item['change']</td>
     <td class="minus" py:content="item['ratio']">item['ratio']</td>
</span>
<span py:if="item['change'] &gt;= 0" py:strip="">
     <td py:content="item['change']">item['change']</td>
     <td py:content="item['ratio']">item['ratio']</td>
</span>
    </tr>
   </tbody>
