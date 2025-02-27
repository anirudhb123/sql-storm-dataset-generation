WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -12, GETDATE()) 
        AND o.o_orderstatus IN ('O', 'F')
),
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        l.l_orderkey
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        MIN(ps.ps_supplycost) AS min_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name,
    SUM(tli.total_line_item_value) AS total_sold,
    COUNT(DISTINCT lo.o_orderkey) AS order_count,
    s.s_name,
    s.s_acctbal,
    coalesce(rc.region_cost, 0) AS regional_cost,
    CASE 
        WHEN SUM(tli.total_line_item_value) > 10000 THEN 'High Value'
        WHEN SUM(tli.total_line_item_value) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    part p
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    TotalLineItems tli ON li.l_orderkey = tli.l_orderkey
LEFT JOIN 
    RankedOrders lo ON lo.o_orderkey = tli.l_orderkey
JOIN 
    supplier s ON s.s_suppkey = li.l_suppkey
LEFT JOIN (
    SELECT 
        r.r_regionkey,
        SUM(ps.ps_supplycost) AS region_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        SupplierCost ps ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        r.r_regionkey
) rc ON rc.r_regionkey = s.s_nationkey
WHERE 
    p.p_retailprice IS NOT NULL
GROUP BY 
    p.p_name, s.s_name, s.s_acctbal, rc.region_cost
HAVING 
    SUM(tli.total_line_item_value) > 0
ORDER BY 
    total_sold DESC,
    p.p_name;
