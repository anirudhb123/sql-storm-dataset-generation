WITH ranked_suppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           COUNT(ps.ps_partkey) AS part_count, 
           SUM(ps.ps_supplycost) AS total_supply_cost, 
           DENSE_RANK() OVER (ORDER BY COUNT(ps.ps_partkey) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
filtered_orders AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_totalprice, 
           o.o_orderstatus
    FROM orders o 
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 50000
),
string_aggregation AS (
    SELECT STRING_AGG(s.s_name, '; ') AS supplier_names, 
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM ranked_suppliers s
    JOIN filtered_orders o ON o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_acctbal > 1000
    )
    GROUP BY s.rank
)
SELECT s.supplier_names, 
       s.order_count, 
       ROW_NUMBER() OVER (ORDER BY s.order_count DESC) AS ranking
FROM string_aggregation s
WHERE s.order_count > 1
ORDER BY ranking;
