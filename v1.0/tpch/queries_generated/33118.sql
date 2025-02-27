WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name 
    FROM 
        SalesCTE cte
    WHERE 
        cte.sales_rank <= 10
),
FilteredSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name 
    FROM 
        SupplierSales ss
    WHERE 
        ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierSales)
)
SELECT 
    tc.c_custkey, 
    tc.c_name AS Top_Customer, 
    fs.s_suppkey, 
    fs.s_name AS High_Cost_Supplier
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    FilteredSuppliers fs ON fs.s_suppkey IS NULL OR tc.c_custkey IS NULL
WHERE 
    tc.c_custkey IS NOT NULL OR fs.s_suppkey IS NOT NULL
ORDER BY 
    tc.c_custkey, fs.s_suppkey;
