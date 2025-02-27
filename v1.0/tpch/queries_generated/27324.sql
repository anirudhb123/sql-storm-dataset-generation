WITH supplier_sales AS (
    SELECT s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_name
),
nation_totals AS (
    SELECT n.n_name, SUM(ss.total_sales) AS total_nation_sales
    FROM nation n
    JOIN supplier_sales ss ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = ss.s_name)
    GROUP BY n.n_name
),
region_totals AS (
    SELECT r.r_name, SUM(nt.total_nation_sales) AS total_region_sales
    FROM region r
    JOIN nation_totals nt ON nt.n_name IN (SELECT n.n_name FROM nation n WHERE n.n_regionkey = r.r_regionkey)
    GROUP BY r.r_name
)
SELECT r.r_name, r.total_region_sales, 
       RANK() OVER (ORDER BY r.total_region_sales DESC) AS region_rank
FROM region_totals r
WHERE r.total_region_sales > 100000
ORDER BY r.total_region_sales DESC;
