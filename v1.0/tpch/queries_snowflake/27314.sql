
WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
SupplierStatistics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        AVG(s.s_acctbal) AS avg_account_balance,
        LISTAGG(DISTINCT n.n_name, ', ') WITHIN GROUP (ORDER BY n.n_name) AS supplied_nations
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.total_available,
    rp.supplier_count,
    ss.s_name,
    ss.parts_supplied,
    ss.avg_account_balance,
    ss.supplied_nations
FROM 
    RankedProducts rp
JOIN 
    SupplierStatistics ss ON ss.parts_supplied >= 5
WHERE 
    rp.rank <= 3
ORDER BY 
    rp.p_brand, rp.total_available DESC;
