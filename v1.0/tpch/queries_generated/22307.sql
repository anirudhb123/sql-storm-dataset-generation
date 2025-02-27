WITH RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_linenumber,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l_shipdate ASC) AS ship_rank
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
),
TotalSales AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM RankedLineItems
    GROUP BY l_orderkey
),
SuppliersWithHighAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_availqty) > 100
),
CustomerOrderInsights AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
)
SELECT 
    n.n_name,
    p.p_brand,
    SUM(t.total_revenue) AS sales_total,
    AVG(c.total_spent) AS avg_customer_spent,
    COUNT(DISTINCT CASE WHEN r.ship_rank = 1 THEN r.l_orderkey END) AS unique_top_sales_orders,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM TotalSales t
JOIN RankedLineItems r ON t.l_orderkey = r.l_orderkey
JOIN part p ON r.l_partkey = p.p_partkey
JOIN supplier s ON r.l_suppkey = s.s_suppkey
JOIN customerOrderInsights c ON s.s_nationkey = c.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN SuppliersWithHighAvailability sh ON r.l_partkey = sh.ps_partkey AND r.l_suppkey = sh.ps_suppkey
WHERE n.n_regionkey IN (
    SELECT r.r_regionkey
    FROM region r
    WHERE r.r_name ILIKE '%' || 'North America' || '%'
)
GROUP BY n.n_name, p.p_brand
HAVING SUM(t.total_revenue) > 1000000 OR COUNT(DISTINCT c.c_custkey) > 50
ORDER BY sales_total DESC NULLS LAST;
