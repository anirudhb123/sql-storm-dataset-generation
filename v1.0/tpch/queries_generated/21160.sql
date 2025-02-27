WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_size,
        p.p_brand
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2 WHERE ps2.ps_partkey = ps.ps_partkey)
),
TotalPrices AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
HighValueOrders AS (
    SELECT 
        tp.o_orderkey,
        tp.total_price,
        ROW_NUMBER() OVER (ORDER BY tp.total_price DESC) AS order_rank
    FROM TotalPrices tp
    WHERE tp.total_price > 1000
)
SELECT 
    rs.s_name,
    rs.p_brand,
    COUNT(DISTINCT hvo.o_orderkey) AS order_count,
    SUM(COALESCE(hvo.total_price, 0)) AS total_revenue,
    MAX(CASE WHEN rs.supplier_rank = 1 THEN rs.ps_availqty END) AS max_avail_qty,
    MIN(CASE WHEN rs.p_size BETWEEN 10 AND 20 THEN rs.ps_availqty END) AS min_avail_qty_within_size
FROM RankedSuppliers rs
LEFT JOIN HighValueOrders hvo ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE rs.p_brand = p.p_brand) LIMIT 1)
GROUP BY rs.s_name, rs.p_brand
HAVING COUNT(DISTINCT hvo.o_orderkey) > 5 OR MAX(rs.ps_availqty) IS NULL
ORDER BY total_revenue DESC NULLS LAST;
