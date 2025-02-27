WITH HighValueOrders AS (
    SELECT o_orderkey, o_totalprice, o_orderdate, 
           DENSE_RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o_orderdate) ORDER BY o_totalprice DESC) AS price_rank
    FROM orders
    WHERE o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'O')
),
SupplierParts AS (
    SELECT ps_partkey, 
           SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM partsupp
    GROUP BY ps_partkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           s.s_name AS supplier_name,
           COALESCE(s.s_acctbal, 0) AS supplier_balance
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT COALESCE(pd.p_name, 'Unknown Part') AS part_name, 
       pd.supplier_name, 
       pd.supplier_balance, 
       COALESCE(hvo.o_orderkey, 0) AS order_key,
       CASE 
           WHEN hvo.o_orderkey IS NOT NULL THEN 'High Value'
           ELSE 'Regular'
       END AS order_type,
       cnt_high_value_orders
FROM PartDetails pd
LEFT JOIN HighValueOrders hvo ON pd.p_partkey = ANY (
    SELECT l.l_partkey 
    FROM lineitem l 
    WHERE l.l_orderkey = hvo.o_orderkey
    GROUP BY l.l_partkey
) 
LEFT JOIN (
    SELECT COUNT(*) AS cnt_high_value_orders, COUNT(DISTINCT o_orderkey) AS cnt_orders 
    FROM HighValueOrders
) AS order_counts ON TRUE
WHERE pd.supplier_balance IS NOT NULL
AND (pd.supplier_balance = (SELECT MAX(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL) 
     OR pd.supplier_balance IN (SELECT s_acctbal FROM supplier WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE 'A%')))
ORDER BY pd.p_brand, pd.p_name;
