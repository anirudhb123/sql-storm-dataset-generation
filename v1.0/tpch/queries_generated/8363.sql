WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate < DATE '2022-01-01'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(ro.o_orderkey) AS total_orders,
        SUM(ro.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank
    FROM 
        CustomerOrders co
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_orders,
    tc.total_spent,
    rn.r_name AS region_name
FROM 
    TopCustomers tc
JOIN 
    supplier s ON tc.total_orders = (SELECT MAX(total_orders) FROM CustomerOrders WHERE total_orders <= tc.total_orders)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region rn ON n.n_regionkey = rn.r_regionkey
WHERE 
    tc.spending_rank <= 10
ORDER BY 
    tc.total_spent DESC;
