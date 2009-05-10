   <tbody>
{foreach from=$list item=item}
    <tr class="{cycle values="odd,even"}">
     <td style="text-align: center">{$smarty.section.item.iteration}</td>
     <td>
      <a href="/stocks/{$item.symbol}">{$item.symbol}</a>
     </td>
     <td>
      <a href="{$item.url}">{$item.name}</a>
     </td>
     <td>
      <strong>{$item.price}</strong>
     </td>
{if $item.change < 0.0}
     <td class="minus">{$item.change}</td>
     <td class="minus">{$item.ratio}</td>
{else}
     <td>{$item.change}</td>
     <td>{$item.ratio}</td>
{/if}
    </tr>
{/foreach}
   </tbody>
