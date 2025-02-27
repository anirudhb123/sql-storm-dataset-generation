WITH RECURSIVE regional_sales AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1994-01-01' AND o.o_orderdate < DATE '1995-01-01'
    GROUP BY n.n_nationkey, n.n_name, r.r_name
    UNION ALL
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM regional_sales rs
    JOIN supplier s ON rs.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1994-01-01' AND o.o_orderdate < DATE '1995-01-01'
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT region_name, SUM(total_sales) AS total_sales_amount
FROM regional_sales
GROUP BY region_name
ORDER BY total_sales_amount DESC
LIMIT 10;
