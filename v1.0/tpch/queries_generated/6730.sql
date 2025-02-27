WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
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
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
ProductPopularity AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 5
)
SELECT 
    TOP 10 R.o_orderkey, 
    R.o_orderdate, 
    R.total_sales, 
    C.c_name AS customer_name, 
    C.total_spent, 
    P.p_name AS popular_product, 
    P.total_quantity_sold
FROM 
    RankedOrders R
JOIN 
    TopCustomers C ON R.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = C.c_custkey)
JOIN 
    ProductPopularity P ON R.o_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_partkey = P.p_partkey)
WHERE 
    R.sales_rank <= 10
ORDER BY 
    R.total_sales DESC, C.total_spent DESC;
