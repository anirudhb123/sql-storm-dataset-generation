WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown size' 
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large' 
        END AS size_category
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(MAX(s.s_acctbal), 0) AS max_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        max_balance > 1000
)
SELECT 
    r.r_name,
    np.n_name,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(ps.total_supply_cost) AS avg_supply_cost,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', rp.size_category, ')'), ', ') AS parts_info
FROM 
    region r
JOIN 
    nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN 
    customer c ON np.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem lp ON o.o_orderkey = lp.l_orderkey
LEFT JOIN 
    RankedParts rp ON lp.l_partkey = rp.p_partkey
LEFT JOIN 
    SupplierStats ps ON lp.l_suppkey = ps.s_suppkey
JOIN 
    FilteredNations fn ON np.n_nationkey = fn.n_nationkey
WHERE 
    r.r_name LIKE 'A%' 
    AND (o.o_orderdate BETWEEN '2023-01-01' AND CURRENT_DATE)
    AND lp.l_returnflag = 'N'
GROUP BY 
    r.r_name, np.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_sales DESC
LIMIT 10;
