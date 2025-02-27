WITH RECURSIVE sales_summary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(o.o_orderkey) AS order_count,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    GROUP BY c.c_custkey, c.c_name
),
supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
region_nation AS (
    SELECT
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name, n.n_name
)
SELECT 
    ss.c_name,
    ss.total_sales,
    ss.order_count,
    rp.region_name,
    rp.nation_name,
    rp.supplier_count,
    COALESCE(sp.ps_supplycost, 0) AS supply_cost,
    COALESCE(sp.ps_availqty, 0) AS available_quantity
FROM sales_summary ss
LEFT JOIN region_nation rp ON ss.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = rp.nation_name LIMIT 1))
LEFT JOIN supplier_parts sp ON ss.c_custkey = (SELECT sp1.s_suppkey FROM supplier_parts sp1 WHERE sp1.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%widget%') LIMIT 1)
WHERE ss.sales_rank <= 10
ORDER BY ss.total_sales DESC;
