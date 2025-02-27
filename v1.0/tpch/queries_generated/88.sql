WITH SupplierSales AS (
    SELECT 
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        s.s_name
),
CustomerRank AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS account_rank
    FROM 
        customer c
)
SELECT 
    n.n_name AS nation,
    COALESCE(SUM(ss.total_sales), 0) AS total_supplier_sales,
    COUNT(DISTINCT cr.c_name) AS high_value_customers
FROM 
    nation n
LEFT JOIN 
    SupplierSales ss ON n.n_nationkey = (
        SELECT s.s_nationkey FROM supplier s WHERE s.s_name = ss.s_name
    )
LEFT JOIN 
    CustomerRank cr ON n.n_nationkey = cr.c_nationkey AND cr.account_rank <= 5
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'Asia')
GROUP BY 
    n.n_name
ORDER BY 
    total_supplier_sales DESC, nation;
