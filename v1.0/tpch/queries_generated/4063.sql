WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
LineItemSummary AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    COALESCE(l.order_count, 0) AS order_count,
    r.r_name AS region_name,
    s.s_name AS top_supplier,
    CASE 
        WHEN h.o_totalprice IS NOT NULL THEN 'High Value'
        ELSE 'Regular'
    END AS order_classification
FROM 
    part p
LEFT JOIN 
    LineItemSummary l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey = (SELECT MAX(o.o_orderkey) FROM HighValueOrders o WHERE o.c_nationkey = n.n_nationkey)
WHERE 
    p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice > 100.00)
ORDER BY 
    total_revenue DESC, order_count DESC;
