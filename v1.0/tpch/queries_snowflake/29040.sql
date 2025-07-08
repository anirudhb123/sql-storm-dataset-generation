
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_address, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
        LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address
),
TopCustomers AS (
    SELECT 
        c.c_custkey AS custkey, 
        c.c_name AS name, 
        c.c_address AS address, 
        c.order_count, 
        c.total_spent,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        CustomerOrders c
)
SELECT 
    r.r_name AS region_name, 
    LISTAGG(CONCAT(c.name, ' (Orders: ', c.order_count, ' | Total: $', c.total_spent), '; ') WITHIN GROUP (ORDER BY c.name) AS customer_summary
FROM 
    TopCustomers c
    JOIN supplier s ON c.custkey = s.s_nationkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE 
    c.rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
