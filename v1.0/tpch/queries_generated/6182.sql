WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredPartSupp AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE 
        rs.rnk <= 5
),
AggregateSales AS (
    SELECT 
        li.l_partkey, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM 
        lineitem li
    GROUP BY 
        li.l_partkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_retailprice,
    COALESCE(as.total_sales, 0) AS total_sales,
    COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
FROM 
    part p
LEFT JOIN 
    AggregateSales as ON p.p_partkey = as.l_partkey
LEFT JOIN 
    FilteredPartSupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_retailprice, 
    as.total_sales
ORDER BY 
    total_supply_cost DESC, 
    total_sales DESC
LIMIT 10;
