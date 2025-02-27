WITH RECURSIVE SupplierCTE AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        1 AS recursion_level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        c.recursion_level + 1
    FROM 
        supplier s
    JOIN 
        SupplierCTE c ON s.s_nationkey = c.s_nationkey
    WHERE 
        s.s_acctbal > c.s_acctbal * 0.5 AND c.recursion_level < 10
),
OrderTotals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
NationRegions AS (
    SELECT 
        n.n_name,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    p.p_name,
    p.p_brand,
    AVG(ps.ps_supplycost) AS avg_supplycost,
    COALESCE(nr.supplier_count, 0) AS total_suppliers,
    SUM(ot.total_revenue) AS total_order_revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY AVG(ps.ps_supplycost) DESC) AS rank
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    OrderTotals ot ON ot.o_orderkey = (
        SELECT TOP 1 o.o_orderkey 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_partkey = p.p_partkey 
        ORDER BY o.o_orderdate DESC
    )
LEFT JOIN 
    NationRegions nr ON p.p_mfgr = nr.n_name
WHERE 
    ps.ps_availqty > 100
GROUP BY 
    p.p_name, p.p_brand, nr.supplier_count
HAVING 
    AVG(ps.ps_supplycost) < (SELECT AVG(ps_availqty) FROM partsupp) 
    AND COUNT(DISTINCT ps.ps_suppkey) > 1
ORDER BY 
    total_order_revenue DESC;
