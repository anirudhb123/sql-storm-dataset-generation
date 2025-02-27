WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 30
), 
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
        AND l.l_shipdate < DATE '2023-12-31'
    GROUP BY 
        l.l_partkey
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
VolumeRanking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'P')
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    ts.total_revenue,
    si.s_name AS supplier_name,
    vr.total_spent,
    vr.customer_rank
FROM 
    RankedParts rp
JOIN 
    TotalSales ts ON rp.p_partkey = ts.l_partkey
LEFT JOIN 
    SupplierInfo si ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = si.s_suppkey)
JOIN 
    VolumeRanking vr ON vr.customer_rank <= 10
WHERE 
    rp.rank <= 5 
ORDER BY 
    total_revenue DESC, rp.p_retailprice ASC;
