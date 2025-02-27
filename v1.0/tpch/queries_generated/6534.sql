WITH RankedOrders AS (
    SELECT 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c_name, 
        total_amount 
    FROM 
        RankedOrders 
    WHERE 
        order_rank = 1
),
SupplierSales AS (
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
        l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY 
        s.s_name
)
SELECT 
    tc.c_name, 
    tc.total_amount, 
    ss.s_name, 
    ss.total_sales
FROM 
    TopCustomers tc
JOIN 
    SupplierSales ss ON ss.total_sales > 10000
ORDER BY 
    total_amount DESC, 
    total_sales DESC;
