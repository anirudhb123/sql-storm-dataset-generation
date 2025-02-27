WITH RegionSales AS (
    SELECT r.r_name AS region_name, SUM(o.o_totalprice) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
),
TopRegions AS (
    SELECT region_name, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM RegionSales
)
SELECT tr.region_name, tr.total_sales, COUNT(DISTINCT l.l_orderkey) AS order_count,
       AVG(o.o_totalprice) AS avg_order_value
FROM TopRegions tr
JOIN orders o ON tr.total_sales = (SELECT SUM(o2.o_totalprice) 
                                     FROM orders o2 
                                     JOIN lineitem l2 ON o2.o_orderkey = l2.l_orderkey 
                                     JOIN partsupp ps2 ON l2.l_partkey = ps2.ps_partkey 
                                     JOIN supplier s2 ON ps2.ps_suppkey = s2.s_suppkey 
                                     JOIN nation n2 ON s2.s_nationkey = n2.n_nationkey 
                                     WHERE n2.n_regionkey = (SELECT r_regionkey FROM region r WHERE r.r_name = tr.region_name))
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY tr.region_name, tr.total_sales
HAVING SUM(o.o_totalprice) > 1000000
ORDER BY tr.sales_rank;
