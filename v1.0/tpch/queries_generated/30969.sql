WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS rn
    FROM orders o 
    WHERE o.o_orderstatus = 'O'
),
avg_discount AS (
    SELECT l.l_orderkey, AVG(l.l_discount) AS avg_discount 
    FROM lineitem l 
    GROUP BY l.l_orderkey
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, r.r_name AS region_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost 
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_suppkey, s.s_name, r.r_name
),
order_details AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, 
           MAX(o.o_orderdate) AS latest_order_date
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT DISTINCT s.region_name, s.s_name, od.total_price, od.latest_order_date, 
                CASE 
                    WHEN avg.avg_discount IS NULL THEN 'N/A'
                    ELSE ROUND(avg.avg_discount * 100, 2)
                END AS avg_discount_percentage,
                COALESCE(oh.rn, 0) AS order_level
FROM supplier_info s
LEFT JOIN order_details od ON s.s_suppkey = od.o_orderkey
LEFT JOIN avg_discount avg ON od.o_orderkey = avg.l_orderkey
LEFT JOIN order_hierarchy oh ON od.o_orderkey = oh.o_orderkey
WHERE s.total_supplycost > 100000
  AND od.total_price > 500
ORDER BY s.region_name, od.total_price DESC;
