WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        CASE 
            WHEN SUM(o.o_totalprice) IS NULL THEN 'NO SPENDING'
            ELSE 'SPENDING'
        END AS spending_status
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierPart AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    COALESCE(SUM(rs.total_revenue), 0) AS total_revenue_generated,
    COALESCE(SUM(sp.parts_supplied), 0) AS total_parts_supplied,
    MAX(rs.revenue_rank) AS highest_revenue_rank
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    CustomerSummary cs ON cs.order_count > 10
LEFT JOIN 
    RankedOrders rs ON rs.o_orderkey IN (SELECT o.o_orderkey FROM orders o)
LEFT JOIN 
    SupplierPart sp ON sp.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 0)
WHERE 
    r.r_name NOT LIKE '%test%' 
    AND ns.n_name IS NOT NULL
GROUP BY 
    r.r_name, ns.n_name
HAVING 
    COUNT(DISTINCT cs.c_custkey) > 0
ORDER BY 
    total_revenue_generated DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
