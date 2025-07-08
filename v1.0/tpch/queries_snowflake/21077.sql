
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 1 AS hierarchy_level
    FROM customer c
    WHERE c.c_acctbal > 1000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.hierarchy_level < 5
), 
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost, 
           COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
AggregatedOrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           SUM(l.l_quantity) AS total_quantity, 
           AVG(l.l_extendedprice) AS avg_extended_price,
           MAX(l.l_discount) AS max_discount
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice 
)
SELECT r.r_name, 
       SUM(COALESCE(ss.total_available_qty, 0)) AS total_supplier_quantity,
       MAX(aos.max_discount) AS highest_discount,
       LISTAGG(DISTINCT ch.c_name, ', ') WITHIN GROUP (ORDER BY ch.c_name) AS customer_names,
       AVG(CASE WHEN aos.total_quantity > 0 THEN aos.avg_extended_price ELSE NULL END) AS average_price
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN AggregatedOrderStats aos ON aos.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderstatus = 'F' AND o.o_orderdate >= DATEADD(year, -1, '1998-10-01')
)
LEFT JOIN CustomerHierarchy ch ON ch.c_nationkey = n.n_nationkey
WHERE r.r_name LIKE '%East%'
GROUP BY r.r_name
HAVING SUM(ss.total_available_qty) > 1000 OR COUNT(DISTINCT ch.c_custkey) > 5
ORDER BY total_supplier_quantity DESC, r.r_name;
