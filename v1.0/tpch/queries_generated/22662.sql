WITH RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
SupplierAvailability AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
ValidOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name,
           CASE WHEN o.o_totalprice > 1000 
                THEN 'High Value Order' 
                WHEN o.o_totalprice BETWEEN 500 AND 1000 
                THEN 'Mid Value Order' 
                ELSE 'Low Value Order' END AS order_value_category
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' 
      AND EXISTS (SELECT 1 FROM lineitem l 
                  WHERE l.l_orderkey = o.o_orderkey 
                    AND l.l_returnflag = 'N')
),
ProductLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, 
           p.p_mfgr, p.p_brand,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_item_rank
    FROM lineitem l
    JOIN part p ON l.l_partkey = p.p_partkey
)
SELECT rc.c_custkey, rc.c_name, rc.c_acctbal, 
       SUM(pli.l_extendedprice) AS total_order_value,
       s.total_available,
       s.avg_supply_cost,
       CASE WHEN COUNT(DISTINCT pli.l_partkey) > 5 THEN 'Diverse Purchase' ELSE 'Selective Purchase' END AS purchase_diversity,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       COALESCE(COUNT(l.l_orderkey) FILTER (WHERE l.l_returnflag = 'Y'), 0) AS return_count,
       CASE WHEN AVG(pli.l_quantity) > 10 THEN 'Bulk Buying' ELSE 'Regular Buying' END AS buying_habit
FROM RankedCustomers rc
LEFT JOIN ValidOrders o ON rc.c_custkey = o.o_custkey
LEFT JOIN ProductLineItems pli ON o.o_orderkey = pli.l_orderkey
LEFT JOIN SupplierAvailability s ON pli.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps)
GROUP BY rc.c_custkey, rc.c_name, rc.c_acctbal, s.total_available, s.avg_supply_cost
HAVING SUM(pli.l_extendedprice) IS NOT NULL
   AND AVG(pli.l_extendedprice) > (SELECT AVG(l.l_extendedprice) FROM lineitem l WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '30 DAY')
ORDER BY total_order_value DESC, rc.c_acctbal DESC;
