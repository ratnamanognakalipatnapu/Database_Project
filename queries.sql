-- Query 1

create view shippedVSCustDemand as
		select distinct cd.customer, cd.item, decode(sum(so.qty),null,0,sum(so.qty)) as suppliedQty,
   decode(sum(distinct cd.qty), null,0,sum(distinct cd.qty)) as demandQty
	from customerDemand cd left outer join shipOrders so on so.recipient= cd.customer and so.item=cd.item
	group by cd.customer, cd.item order by cd.customer, cd.item;

--Query 2

create view totalManufItems as
	select distinct mo.item, decode(sum(mo.qty),null,0,sum(mo.qty)) as totalManufQty
 		from manufOrders mo group by mo.item order by mo.item;


-- Query 3
create view matsUsedVsShipped as

	select temp.manuf, temp.matItem, temp.requiredQty as requiredQty, decode(sum( so.qty),null,0,sum( so.qty)) as shippedQty
	from (select mo.manuf, bom.matItem,
				decode(sum( mo.qty*bom.qtyMatPerItem), null,0,sum( mo.qty*bom.qtyMatPerItem)) as requiredQty
				from
				manufOrders mo, billOfMaterials bom where bom.prodItem=mo.item group by mo.manuf, bom.matItem) temp
	left outer join
 shipOrders so on so.recipient= temp.manuf and so.item=temp.matItem
group by temp.manuf, temp.matItem, temp.requiredQty order by temp.manuf, temp.matItem;

-- Query 4
create view producedVsShipped as
select distinct mo.manuf, mo.item, decode(sum(so.qty),null,0,sum(so.qty)) as shippedOutQty,
decode(sum(distinct mo.qty), null,0,sum(distinct mo.qty)) as orderedQty
from manufOrders mo left outer join shipOrders so on so.sender= mo.manuf and so.item=mo.item
group by mo.manuf, mo.item order by mo.manuf, mo.item;

-- Query 5
create view suppliedVsShipped as
	select distinct suo.supplier, suo.item, decode(sum(distinct suo.qty), null,0,sum(distinct suo.qty)) as suppliedQty,
	decode(sum(so.qty),null,0,sum(so.qty)) as shippedQty
	from supplyOrders suo left outer join shipOrders so on so.sender= suo.supplier and so.item=suo.item
	group by suo.supplier, suo.item order by suo.supplier, suo.item;



-- Query 6
create view perSupplierCost as
	select sud.supplier,
				nvl(CASE
		    when temp.price > sud.amt1 and temp.price<sud.amt2 then (temp.price-((temp.price-sud.amt1)*sud.disc1) )
				when temp.price > sud.amt2	then (temp.price-((sud.amt2-sud.amt1)*sud.disc1 +(temp.price-sud.amt2)*sud.disc2) )
		    when temp.price < sud.amt1 then temp.price
		    END,0) as cost
				from
				(select so.supplier, decode(sum(so.qty*sup.ppu),null,0,sum(so.qty*sup.ppu)) as price
				from supplyOrders so, supplyUnitPricing sup
				where so.supplier=sup.supplier and so.item=sup.item
				group by so.supplier) temp
				right outer join supplierDiscounts sud on temp.supplier=sud.supplier;


-- Query 7
create view perManufCost as

	select * from supplyOrders;



-- Query 8
create view perShipperCost as

	select * from supplyOrders;


-- Query 9
create view totalCostBreakDown as

	select * from supplyOrders;



-- Query 10
create view customersWithUnsatisfiedDemand as
	select distinct cd.customer
 		from customerDemand cd where cd.customer not in
        (select so.recipient from shipOrders so where cd.item=so.item and cd.customer=so.recipient and cd.qty<=(select sum(so1.qty) from shipOrders so1 where so1.recipient=so.recipient and so1.item= cd.item));



-- Query 11
create view suppliersWithUnsentOrders as
	select distinct suo.supplier
 		from supplyOrders suo where suo.supplier not in
		(select so.sender from shipOrders so where so.qty>=suo.qty and suo.item=so.item and suo.supplier=so.sender);


-- Query 12
create view manufsWoutEnoughMats as
	select temp2.manuf
	from(select temp.manuf, temp.matItem, temp.requiredQty as requiredQty, decode(sum( so.qty),null,0,sum( so.qty)) as shippedQty
				from(select mo.manuf, bom.matItem,
							decode(sum( mo.qty*bom.qtyMatPerItem), null,0,sum( mo.qty*bom.qtyMatPerItem)) as requiredQty
							from manufOrders mo, billOfMaterials bom where bom.prodItem=mo.item group by mo.manuf, bom.matItem) temp
				left outer join	shipOrders so on so.recipient= temp.manuf and so.item=temp.matItem
				group by temp.manuf, temp.matItem, temp.requiredQty order by temp.manuf, temp.matItem) temp2
 where temp2.requiredQty> temp2.shippedQty
group by temp2.manuf;


-- Query 13
create view manufsWithUnsentOrders as
	select distinct mo.manuf
 		from manufOrders mo where mo.manuf not in
		(select so.sender from shipOrders so where so.qty=mo.qty and mo.item=so.item and mo.manuf=so.sender);
