WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_income,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(roi.total_income) AS total_spent
    FROM 
        customer c
    JOIN 
        RankedOrders roi ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = roi.o_orderkey)
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    c.c_name, 
    c.c_address, 
    c.c_phone, 
    tc.total_spent
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_custkey = c.c_custkey
ORDER BY 
    tc.total_spent DESC;