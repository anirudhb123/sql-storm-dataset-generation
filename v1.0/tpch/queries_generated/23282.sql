WITH RECURSIVE cte_sales AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
cte_supplier_info AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        COALESCE(SUM(ps.ps_availqty), 0) AS available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
cte_nation_sales AS (
    SELECT
        n.n_name,
        SUM(o.o_totalprice) AS nation_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS nation_rank
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
)
SELECT 
    n.n_name AS nation,
    s.s_name AS supplier,
    pi.p_name AS part,
    s.available_quantity,
    s.total_supply_cost,
    CASE 
        WHEN s.total_supply_cost IS NULL THEN 'No cost info'
        WHEN s.available_quantity < 10 THEN 'Low stock'
        ELSE 'Sufficient stock'
    END AS stock_status,
    ss.total_sales AS sales_per_cust,
    ns.nation_sales AS total_nation_sales
FROM cte_supplier_info s
JOIN part pi ON s.p_partkey = pi.p_partkey
LEFT JOIN cte_sales ss ON ss.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = pi.p_partkey)
JOIN cte_nation_sales ns ON ns.n_name = (SELECT n.n_name FROM nation n 
                                         JOIN customer c ON n.n_nationkey = c.c_nationkey 
                                         JOIN orders o ON c.c_custkey = o.o_custkey 
                                         WHERE o.o_orderkey IN (SELECT o_orderkey FROM cte_sales) LIMIT 1)
WHERE s.available_quantity IS NOT NULL
  AND s.total_supply_cost IS NOT NULL
  AND s.s_name NOT LIKE '%Banned%'
ORDER BY ns.nation_sales DESC, s.total_supply_cost ASC
FETCH FIRST 100 ROWS ONLY;
