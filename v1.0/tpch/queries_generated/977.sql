WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
LineitemStats AS (
    SELECT 
        l.l_orderkey,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    SUM(COALESCE(l.l_quantity, 0)) AS total_quantity,
    AVG(oss.avg_price_after_discount) AS avg_price_after_discount,
    COUNT(DISTINCT oo.o_orderkey) AS total_orders,
    SUM(COALESCE(ss.total_supplycost, 0)) AS total_supplycost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    LineitemStats oss ON l.l_orderkey = oss.l_orderkey
JOIN 
    RankedOrders oo ON l.l_orderkey = oo.o_orderkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, n.n_name, s.s_name
HAVING 
    SUM(COALESCE(l.l_quantity, 0)) > 100
ORDER BY 
    total_quantity DESC;
