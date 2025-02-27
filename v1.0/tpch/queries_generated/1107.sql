WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND c.c_acctbal IS NOT NULL
),
ActiveSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 5000
    GROUP BY s.s_suppkey, s.s_name
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice > 100 THEN 'High Price'
            ELSE 'Affordable'
        END AS price_category
    FROM part p
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    p.p_name,
    p.price_category
FROM RankedOrders r
LEFT JOIN lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN ActiveSuppliers s ON l.l_suppkey = s.s_suppkey
JOIN HighValueParts p ON l.l_partkey = p.p_partkey
WHERE r.rn <= 5
  AND (s.total_available IS NULL OR s.total_available > 0)
GROUP BY r.o_orderkey, r.o_orderdate, p.p_name, p.price_category
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY r.o_orderdate DESC, total_revenue DESC;
