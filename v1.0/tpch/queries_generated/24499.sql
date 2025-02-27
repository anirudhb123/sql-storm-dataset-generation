WITH RECURSIVE cust_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_orderstatus, 1 AS level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('F', 'O')

    UNION ALL

    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_orderstatus, co.level + 1
    FROM cust_orders co
    JOIN orders o ON co.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F' AND co.level < 5
),
semi_exclusive_parts AS (
    SELECT DISTINCT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_size IS NOT NULL AND p.p_size % 2 = 0
    AND p.p_retailprice > (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
        WHERE p2.p_size IS NOT NULL
        HAVING COUNT(*) > 1
    )
),
supplier_count AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
order_summaries AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS row_num
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' AND l.l_linestatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT co.c_custkey, co.c_name, 
       COUNT(DISTINCT ps.ps_partkey) AS part_count,
       SUM(os.total_price) AS total_order_value,
       MAX(su.supplier_count) AS max_suppliers
FROM cust_orders co
LEFT JOIN semi_exclusive_parts ps ON EXISTS (
    SELECT 1
    FROM supplier_count s
    WHERE s.ps_partkey = ps.p_partkey AND s.supplier_count > 1
)
JOIN order_summaries os ON co.o_orderkey = os.o_orderkey
LEFT JOIN supplier_count su ON ps.p_partkey = su.ps_partkey
WHERE co.level <= 3
AND co.o_orderdate > '2022-01-01'
GROUP BY co.c_custkey, co.c_name
HAVING MAX(su.supplier_count) IS NOT NULL
ORDER BY total_order_value DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
