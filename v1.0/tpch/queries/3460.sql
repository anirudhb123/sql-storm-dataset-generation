
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierPerformance AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name,
    p.p_brand,
    rp.o_orderdate,
    rp.o_totalprice AS totalprice,
    sp.total_quantity,
    sp.total_revenue,
    CASE 
        WHEN sp.total_revenue IS NULL THEN 'No Sales' 
        ELSE 'Sold' 
    END AS sales_status,
    CONCAT('Supplier Key: ', s.s_suppkey, ', Nation Key: ', n.n_nationkey) AS supplier_info
FROM 
    part p
LEFT JOIN 
    SupplierPerformance sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    RankedOrders rp ON rp.o_orderkey = (SELECT o.o_orderkey 
                                         FROM orders o 
                                         JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
                                         WHERE l.l_partkey = p.p_partkey 
                                         ORDER BY o.o_orderdate DESC LIMIT 1)
LEFT JOIN 
    supplier s ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 100.00
ORDER BY 
    rp.o_orderdate DESC NULLS LAST, sp.total_revenue DESC;
