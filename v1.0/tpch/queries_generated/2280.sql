WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        rn <= 3
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(os.total_sales) AS total_customer_sales
    FROM 
        customer c
    JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation,
    SUM(cs.total_customer_sales) AS nation_sales,
    COUNT(DISTINCT cs.c_custkey) AS unique_customers,
    MAX(cs.total_customer_sales) AS max_sales,
    STRING_AGG(DISTINCT ts.s_name, ', ') AS top_suppliers
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerSales cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    nation_sales DESC;
