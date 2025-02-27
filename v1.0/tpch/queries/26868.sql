
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(ps.ps_partkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
        STRING_AGG(DISTINCT s.s_address, ', ') AS addresses
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.supplier_count,
        p.suppliers,
        p.addresses,
        n_r.r_name,
        n_r.n_name,
        d.cust_count
    FROM 
        RankedParts p
    LEFT JOIN 
        (SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name 
         FROM nation n 
         JOIN region r ON n.n_regionkey = r.r_regionkey) AS n_r ON n_r.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = p.p_partkey LIMIT 1)
    LEFT JOIN 
        (SELECT c.c_nationkey, COUNT(c.c_custkey) AS cust_count 
         FROM customer c GROUP BY c.c_nationkey) AS d ON d.c_nationkey = n_r.n_nationkey
)
SELECT 
    p_partkey,
    p_name,
    p_brand,
    supplier_count,
    suppliers,
    addresses,
    r_name AS region,
    n_name AS nation,
    cust_count
FROM 
    FilteredParts 
WHERE 
    supplier_count > 1 
ORDER BY 
    supplier_count DESC, 
    p_name;
