WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),

NationRegion AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),

FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' -- Filtering for orders in 2023
)

SELECT 
    p.p_name,
    s.s_name,
    ns.region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    MAX(s.s_acctbal) AS max_account_balance,
    AVG(s.s_acctbal) AS avg_account_balance,
    COALESCE(MAX(rn), 0) AS top_supplier_rank  -- In case there are no suppliers for a part
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    NationRegion ns ON s.s_nationkey = ns.n_nationkey
WHERE 
    p.p_size > 20
GROUP BY 
    p.p_name, s.s_name, ns.region_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC
UNION ALL
SELECT 
    'Total' AS p_name,
    NULL AS s_name, 
    NULL AS region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)),
    COUNT(DISTINCT o.o_orderkey),
    NULL, NULL,
    NULL
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 20;
