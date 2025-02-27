WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS number_of_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
        AND o.o_orderdate < '2023-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.number_of_orders,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
),
TopSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.total_sales,
        r.number_of_orders
    FROM 
        RankedSuppliers r
    WHERE 
        r.sales_rank <= 10
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        cs.orders_count
    FROM 
        CustomerSummary cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
)

SELECT 
    t.s_name AS supplier_name,
    t.total_sales AS supplier_sales,
    h.c_name AS customer_name,
    h.total_spent AS customer_spent
FROM 
    TopSuppliers t
JOIN 
    lineitem l ON l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = t.s_suppkey)
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    HighValueCustomers h ON o.o_custkey = h.c_custkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    t.total_sales DESC, h.total_spent DESC;
