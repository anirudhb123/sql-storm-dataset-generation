WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
           CASE 
               WHEN o.o_orderstatus = 'F' THEN 'Finished'
               WHEN o.o_orderstatus IS NULL THEN 'Unknown'
               ELSE 'Pending' 
           END AS order_status_description
    FROM orders o
), SupplierAvailability AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty,
           CASE 
               WHEN SUM(ps.ps_availqty) IS NULL OR SUM(ps.ps_availqty) = 0 THEN 'Unavailable'
               ELSE 'Available'
           END AS availability_status
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), PartPriceAdjustment AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, 
           CASE 
               WHEN p.p_retailprice IS NULL THEN 0
               ELSE p.p_retailprice * 1.1 
           END AS adjusted_price
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
), OrderDetails AS (
    SELECT lo.l_orderkey, lo.l_partkey, lo.l_extendedprice,
           lo.l_discount, RANK() OVER (PARTITION BY lo.l_orderkey ORDER BY lo.l_extendedprice DESC) AS line_item_rank
    FROM lineitem lo
    WHERE lo.l_returnflag = 'N'
    AND lo.l_discount > 0.05
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.total_avail_qty,
    pp.p_name,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS final_price,
    MAX(od.line_item_rank) AS highest_line_item_rank,
    COALESCE(su.availability_status, 'Unknown') AS supplier_availability,
    o.order_status_description
FROM RankedOrders o
LEFT JOIN SupplierAvailability su ON EXISTS (
    SELECT 1
    FROM Supplier s
    WHERE s.s_suppkey = su.ps_suppkey AND s.s_nationkey IN (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
    )
) 
JOIN OrderDetails od ON o.o_orderkey = od.l_orderkey
JOIN PartPriceAdjustment pp ON od.l_partkey = pp.p_partkey
WHERE o.price_rank <= 5
OR pp.adjusted_price > 100
GROUP BY o.o_orderkey, o.o_orderdate, o.order_status_description, pp.p_name, su.total_avail_qty
HAVING COUNT(od.l_partkey) >= 2
ORDER BY o.o_orderdate DESC, final_price DESC
LIMIT 10;
