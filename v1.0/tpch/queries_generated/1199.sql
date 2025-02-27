WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
ProductSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS avg_discount
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    SUM(os.total_sales) AS total_sales,
    COUNT(DISTINCT hc.c_custkey) AS high_value_customers,
    AVG(ps.total_quantity) AS avg_product_quantity,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')'), ', ') AS top_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.supplier_rank = 1
LEFT JOIN 
    orders o ON s.s_suppkey = o.o_custkey  -- Joining with orders, which needs modification to properly join by keys
LEFT JOIN 
    HighValueCustomers hc ON o.o_custkey = hc.c_custkey
LEFT JOIN 
    OrderSummary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN 
    ProductSales ps ON ps.p_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#1' LIMIT 1) --  Correlated subquery example
WHERE 
    r.r_name IS NOT NULL OR r.r_regionkey IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    SUM(os.total_sales) > 5000
ORDER BY 
    total_sales DESC;
