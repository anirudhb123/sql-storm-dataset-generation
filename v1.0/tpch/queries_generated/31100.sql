WITH RECURSIVE sales_ranked AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_name
),
supplier_info AS (
    SELECT 
        p.p_partkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, s.s_name
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        total_sales,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY total_sales DESC) AS nation_order
    FROM sales_ranked sr
    JOIN customer c ON sr.c_name = c.c_name
    WHERE sr.total_sales > 10000
)
SELECT 
    r.r_name,
    SUM(CASE WHEN hvo.nation_order <= 10 THEN hvo.total_sales ELSE 0 END) AS top_sales,
    COUNT(DISTINCT hvo.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT s.s_name || ' (Cost: ' || total_supply_cost || ')', ', ') AS suppliers
FROM region r
LEFT JOIN high_value_orders hvo ON r.r_regionkey = hvo.c_nationkey
LEFT JOIN supplier_info s ON hvo.c_nationkey = s.p_partkey
WHERE hvo.nation_order IS NOT NULL
GROUP BY r.r_name
HAVING SUM(CASE WHEN hvo.nation_order <= 10 THEN hvo.total_sales ELSE 0 END) > 50000
ORDER BY top_sales DESC;
