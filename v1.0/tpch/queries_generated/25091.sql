WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS n_name, r.r_name AS r_name, 
           CONCAT(s.s_name, ' (', n.n_name, ', ', r.r_name, ')') AS full_supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_container,
           CONCAT(p.p_name, ' - ', p.p_brand, ' [', p.p_container, ']') AS full_part_info
    FROM part p
),
OrderInfo AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    sd.full_supplier_info,
    pd.full_part_info,
    oi.o_orderkey,
    oi.o_orderdate,
    oi.total_revenue,
    COUNT(DISTINCT oi.o_orderkey) AS order_count,
    DATE_PART('year', oi.o_orderdate) AS order_year
FROM SupplierDetails sd
JOIN PartDetails pd ON pd.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_suppkey = sd.s_suppkey
)
JOIN OrderInfo oi ON oi.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey = sd.s_suppkey
    )
)
WHERE oi.total_revenue > 10000
GROUP BY sd.full_supplier_info, pd.full_part_info, oi.o_orderkey, oi.o_orderdate
ORDER BY order_year DESC, total_revenue DESC;
