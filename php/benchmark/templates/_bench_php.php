   <tbody>
<?php $i = 0; ?>
<?php foreach ($list as $item) { ?>
    <tr class="<?php echo ++$i % 2 == 0 ? 'even' : 'odd' ?>">
     <td style="text-align: center"><?php echo $i ?></td>
     <td>
      <a href="/stocks/<?php echo $item['symbol'] ?>"><?php echo $item['symbol'] ?></a>
     </td>
     <td>
      <a href="<?php echo $item['url'] ?>"><?php echo $item['name'] ?></a>
     </td>
     <td>
      <strong><?php echo $item['price'] ?></strong>
     </td>
<?php     if ($item['change'] < 0.0) { ?>
     <td class="minus"><?php echo $item['change'] ?></td>
     <td class="minus"><?php echo $item['ratio'] ?></td>
<?php     } else { ?>
     <td><?php echo $item['change'] ?></td>
     <td><?php echo $item['ratio'] ?></td>
<?php     } ?>
    </tr>
<?php } ?>
   </tbody>
