WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p 
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSales AS (
    SELECT 
        rs.p_partkey,
        rs.p_name,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000.00
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        orders o
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
HighValueCustomers AS (
    SELECT 
        co.o_custkey,
        COALESCE(c.c_name, 'Unknown') AS customer_name,
        co.total_order_value
    FROM 
        CustomerOrders co
    LEFT JOIN 
        customer c ON co.o_custkey = c.c_custkey
    WHERE 
        co.total_order_value > 5000
)
SELECT 
    ts.p_name,
    ts.total_sales,
    si.s_name AS supplier_name,
    si.s_acctbal AS supplier_account_balance,
    hvc.customer_name,
    hvc.total_order_value
FROM 
    TopSales ts
LEFT JOIN 
    SupplierInfo si ON ts.p_partkey = si.ps_partkey
LEFT JOIN 
    HighValueCustomers hvc ON hvc.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        JOIN orders o ON c.c_custkey = o.o_custkey 
        WHERE o.o_totalprice > 10000
    )
ORDER BY 
    ts.total_sales DESC, 
    si.s_acctbal DESC
LIMIT 15;
