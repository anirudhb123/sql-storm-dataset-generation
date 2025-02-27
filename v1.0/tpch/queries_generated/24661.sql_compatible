
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
RecentPurchases AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS purchase_amount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_name,
    p.p_brand,
    r.r_name AS supplier_region,
    COALESCE(sp.total_avail, 0) AS available_parts,
    COALESCE(rp.purchase_amount, 0) AS last_year_purchase,
    so.rank_order
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    supplier s ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RecentPurchases rp ON rp.l_orderkey = (
        SELECT 
            l.l_orderkey
        FROM 
            lineitem l
        WHERE 
            l.l_partkey = p.p_partkey
        ORDER BY 
            l.l_extendedprice DESC
        LIMIT 1
    )
JOIN 
    RankedOrders so ON so.o_orderkey = rp.l_orderkey
WHERE 
    (p.p_brand LIKE 'BrandA%' OR p.p_brand IS NULL)
    AND (p.p_retailprice BETWEEN 10 AND 100)
    AND (sp.total_avail IS NULL OR sp.total_avail > 0)
ORDER BY 
    p.p_name, so.rank_order DESC;
