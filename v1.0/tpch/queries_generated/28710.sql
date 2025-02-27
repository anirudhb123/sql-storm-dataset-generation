WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_by_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size
),
FilteredParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_brand, 
        rp.total_cost,
        rp.rank_by_cost
    FROM 
        RankedParts rp
    WHERE 
        rp.rank_by_cost <= 5
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_brand,
    fp.total_cost,
    bg.r_name AS best_selling_region
FROM 
    FilteredParts fp
JOIN 
    supplier s ON s.s_suppkey = (SELECT TOP 1 ps.ps_suppkey 
                                   FROM partsupp ps 
                                   WHERE ps.ps_partkey = fp.p_partkey 
                                   ORDER BY ps.ps_supplycost DESC)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region bg ON n.n_regionkey = bg.r_regionkey
ORDER BY 
    fp.total_cost DESC;
