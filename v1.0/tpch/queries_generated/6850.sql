WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_in_nation
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        c.c_nationkey,
        r.r_name AS nation_name,
        rc.c_name AS customer_name,
        rc.total_spent
    FROM 
        RankedCustomers rc
    JOIN 
        nation c ON rc.c_custkey = c.n_nationkey
    JOIN 
        region r ON c.n_regionkey = r.r_regionkey
    WHERE 
        rc.rank_in_nation <= 5
),
OrdersByTopCustomers AS (
    SELECT 
        t.nation_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_orders_value
    FROM 
        TopCustomers t
    JOIN 
        orders o ON t.customer_name = o.o_custkey
    GROUP BY 
        t.nation_name
)
SELECT 
    nation_name,
    order_count,
    total_orders_value,
    ROUND(total_orders_value / NULLIF(order_count, 0), 2) AS avg_order_value
FROM 
    OrdersByTopCustomers
ORDER BY 
    total_orders_value DESC;
