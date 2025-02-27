WITH CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.custkey,
        c.name,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        (SELECT c.custkey, c.name FROM customer c) c
    JOIN 
        CustomerSales cs ON c.custkey = cs.c_custkey
    WHERE 
        cs.total_sales > 10000
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    tc.name AS top_customer,
    tc.sales_rank,
    ss.s_name AS supplier_name,
    ss.total_supply_cost,
    ss.supplied_parts
FROM 
    TopCustomers tc
LEFT JOIN 
    SupplierStats ss ON ss.total_supply_cost > 50000
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.sales_rank, ss.total_supply_cost DESC;

-- Additional filters can be added to exclude nulls.
