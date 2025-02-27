WITH regional_sales AS (
    SELECT n.n_name AS nation_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY n.n_name
),
top_nations AS (
    SELECT nation_name, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM regional_sales
),
high_performers AS (
    SELECT nation_name, total_sales
    FROM top_nations
    WHERE sales_rank <= 5
)
SELECT hp.nation_name, hp.total_sales, p.p_mfgr, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
FROM high_performers hp
JOIN supplier s ON hp.nation_name IN (
        SELECT n.n_name FROM nation n WHERE s.s_nationkey = n.n_nationkey
    )
JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY hp.nation_name, hp.total_sales, p.p_mfgr, p.p_name
ORDER BY hp.total_sales DESC, total_supply_cost DESC;
