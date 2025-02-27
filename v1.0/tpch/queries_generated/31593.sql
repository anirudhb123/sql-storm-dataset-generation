WITH RECURSIVE SalesCTE AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate

    UNION ALL

    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, s.total_sales + SUM(l.l_extendedprice * (1 - l.l_discount))
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN SalesCTE s ON s.c_custkey = c.c_custkey AND s.o_orderkey < o.o_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, s.total_sales
),

RankedSales AS (
    SELECT c.c_custkey, c.c_name, SUM(s.total_sales) AS total_sales, 
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(s.total_sales) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN SalesCTE s ON c.c_custkey = s.c_custkey
    GROUP BY c.c_custkey, c.c_name
)

SELECT r.r_name, COUNT(DISTINCT ns.n_nationkey) AS nation_count,
       MAX(rs.total_sales) AS max_total_sales,
       COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty
FROM region r
JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN RankedSales rs ON rs.c_custkey = s.s_suppkey
WHERE rs.sales_rank = 1 AND rs.total_sales IS NOT NULL
GROUP BY r.r_name
ORDER BY nation_count DESC, max_total_sales DESC;
