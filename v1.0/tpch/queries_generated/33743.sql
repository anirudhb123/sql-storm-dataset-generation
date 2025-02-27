WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        1 AS depth
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 0

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        sh.depth + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        sh.depth < 5
),
MaxOrderValue AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(mov.total_order_value, 0) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        MaxOrderValue mov ON c.c_custkey = mov.o_custkey
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) 
            FROM customer c2 
            WHERE c2.c_nationkey = c.c_nationkey
        )
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(l.l_quantity) AS total_quantity_supplied,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    c.c_name AS customer_name,
    SUM(sp.total_value_supplied) AS total_supplier_value,
    MAX(sp.total_quantity_supplied) AS max_quantity_supplied,
    COUNT(DISTINCT sh.s_suppkey) AS unique_suppliers,
    CASE 
        WHEN SUM(sp.total_value_supplied) > 100000 THEN 'High Value'
        ELSE 'Low Value'
    END AS supplier_value_category
FROM 
    CustomerInfo c
LEFT JOIN 
    SupplierPerformance sp ON c.c_custkey = sp.s_suppkey
LEFT JOIN 
    SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE 
    c.total_order_value > 50000
GROUP BY 
    c.c_name
HAVING 
    MAX(sp.total_quantity_supplied) > 10
ORDER BY 
    total_supplier_value DESC;
