WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
), TopCustomers AS (
    SELECT 
        c.custkey,
        c.name,
        c.nationkey,
        c.total_orders,
        c.total_spent,
        c.avg_order_value
    FROM 
        CustomerOrders c
    WHERE 
        c.rank <= 5
)
SELECT 
    n.n_name AS nation,
    SUM(tc.total_spent) AS total_spent_by_nation,
    COUNT(tc.custkey) AS total_top_customers,
    AVG(tc.avg_order_value) AS avg_order_value_for_top_customers,
    STRING_AGG(tc.name, ', ') AS customer_names
FROM 
    TopCustomers tc
JOIN 
    nation n ON tc.nationkey = n.n_nationkey
GROUP BY 
    n.n_name
HAVING 
    SUM(tc.total_spent) > 100000
ORDER BY 
    total_spent_by_nation DESC;
