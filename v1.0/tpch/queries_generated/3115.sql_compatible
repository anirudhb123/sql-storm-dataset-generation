
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
RelevantParts AS (
    SELECT 
        p.p_partkey,
        p.p_brand,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_brand LIKE 'BrandA%' AND p.p_retailprice > 100
),
LineItemsWithTotal AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ns.n_name AS nation_name,
    COALESCE(SUM(ss.total_availqty), 0) AS total_available_quantity,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    AVG(l.total_amount) AS average_order_value,
    oh.order_rank
FROM 
    nation ns
LEFT JOIN 
    SupplierSummary ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN 
    RelevantParts rp ON EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey = rp.p_partkey 
        AND ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ns.n_nationkey)
    )
LEFT JOIN 
    LineItemsWithTotal l ON EXISTS (
        SELECT 1 
        FROM orders o 
        WHERE o.o_orderkey = l.l_orderkey 
        AND o.o_orderstatus = 'O'
    )
JOIN 
    RankedOrders oh ON l.l_orderkey = oh.o_orderkey
WHERE 
    ns.n_regionkey IS NOT NULL
GROUP BY 
    ns.n_name, oh.order_rank
ORDER BY 
    total_available_quantity DESC,
    average_order_value DESC;
