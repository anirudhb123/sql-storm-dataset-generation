WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartSupplyStats AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderstatus,
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey,
           CASE 
               WHEN l.l_discount < 0.1 THEN 'Low Discount'
               WHEN l.l_discount BETWEEN 0.1 AND 0.2 THEN 'Moderate Discount'
               ELSE 'High Discount'
           END AS discount_category,
           COUNT(*) OVER (PARTITION BY l.l_orderkey) AS lines_in_order
    FROM lineitem l
    WHERE l.l_shipdate > '2023-01-01'
)

SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_mfgr,
       COALESCE(ss.unique_suppliers, 0) AS num_suppliers,
       COALESCE(rl.rn, 0) AS rank_of_supplier,
       COALESCE(hvo.order_rank, 0) AS high_value_order_rank,
       fl.discount_category, fl.lines_in_order
FROM part p
LEFT JOIN PartSupplyStats ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN RankedSuppliers rl ON rl.s_suppkey = (SELECT MIN(s.s_suppkey) 
                                                  FROM RankedSuppliers s 
                                                  WHERE s.rn = 1)
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey = (SELECT l.l_orderkey 
                                                    FROM lineitem l 
                                                    WHERE l.l_partkey = p.p_partkey 
                                                    LIMIT 1)
LEFT JOIN FilteredLineItems fl ON fl.l_partkey = p.p_partkey
WHERE p.p_retailprice IS NOT NULL
  AND (SELECT COUNT(*) FROM orders o WHERE o.o_orderstatus = 'F') > 0
ORDER BY p.p_partkey, p.p_retailprice DESC;
