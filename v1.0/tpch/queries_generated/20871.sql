WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartCostDetails AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost) AS total_supply_cost, 
        COUNT(*) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
MaxRetailPrice AS (
    SELECT 
        p.p_partkey,
        MAX(p.p_retailprice) AS max_price
    FROM 
        part p
    GROUP BY 
        p.p_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.max_price, 0) AS max_retail_price,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(c.c_name, 'No Customer') AS customer_name,
    CASE 
        WHEN (c.c_acctbal IS NULL OR c.c_acctbal < 0) THEN 'Negative Balance'
        ELSE 'Positive Balance'
    END AS balance_status,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
FROM 
    part p
LEFT JOIN 
    MaxRetailPrice r ON p.p_partkey = r.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    RankedSuppliers s ON r.s_partkey = s.s_suppkey AND s.rn = 1
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND (s.s_name IS NOT NULL OR l.l_shipdate < CURRENT_DATE - INTERVAL '30 days')
GROUP BY 
    p.p_partkey, p.p_name, r.max_price, s.s_name, c.c_name, c.c_acctbal
HAVING 
    SUM(l.l_quantity) > 0
ORDER BY 
    net_revenue DESC
LIMIT 10;
