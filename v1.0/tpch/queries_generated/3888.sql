WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '2023-06-01' AND DATE '2023-06-30'
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT 
    R.rn, 
    R.o_orderkey, 
    R.o_totalprice, 
    T.c_name, 
    COALESCE(H.total_sales, 0) AS total_sales_june,
    CASE 
        WHEN T.total_spent IS NULL THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_status
FROM 
    RankedOrders R
LEFT JOIN 
    HighValueLineItems H ON R.o_orderkey = H.l_orderkey
LEFT JOIN 
    TopCustomers T ON R.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = T.c_custkey)
WHERE 
    R.rn <= 10
ORDER BY 
    R.o_totalprice DESC, 
    T.total_spent DESC;
