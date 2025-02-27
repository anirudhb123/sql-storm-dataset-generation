WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate <= CURRENT_DATE AND 
        l.l_quantity > 0
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
ranked_orders AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        co.order_year,
        SUM(co.total_spent) AS yearly_spent,
        ROW_NUMBER() OVER (PARTITION BY cust.c_custkey ORDER BY SUM(co.total_spent) DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_orders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        cust.c_custkey, cust.c_name, co.order_year
),
top_customers AS (
    SELECT 
        r.custkey,
        r.c_name,
        r.yearly_spent
    FROM 
        ranked_orders r
    WHERE 
        r.rank = 1 AND 
        r.yearly_spent > (
            SELECT AVG(yearly_spent)
            FROM ranked_orders
            WHERE order_year = r.order_year
        )
)
SELECT 
    t.c_name AS CustomerName,
    SUM(ps.ps_supplycost * l.l_quantity) AS TotalSpentOnSuppliers,
    CASE
        WHEN SUM(ps.ps_supplycost * l.l_quantity) IS NULL THEN 'No Spending'
        ELSE 'Spending Exists'
    END AS SpendingStatus
FROM 
    top_customers t
LEFT JOIN 
    partsupp ps ON ps.ps_partkey IN (
        SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (
            SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = t.custkey
        )
    )
GROUP BY 
    t.c_name
ORDER BY 
    TotalSpentOnSuppliers DESC 
LIMIT 10;
