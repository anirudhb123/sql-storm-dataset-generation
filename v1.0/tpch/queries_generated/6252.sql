WITH RankedOrders AS (
    SELECT 
        o.orderkey, 
        c.custkey, 
        c.c_name, 
        o.orderstatus, 
        o.totalprice, 
        o.orderdate, 
        RANK() OVER (PARTITION BY c.custkey ORDER BY o.totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.custkey = c.custkey
),
TopCustomers AS (
    SELECT 
        c.custkey, 
        c.c_name, 
        SUM(o.totalprice) AS total_spent
    FROM RankedOrders ro
    JOIN orders o ON ro.orderkey = o.orderkey
    JOIN customer c ON ro.custkey = c.custkey
    WHERE ro.rank <= 5
    GROUP BY c.custkey, c.c_name
),
PopularParts AS (
    SELECT 
        ps.partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    JOIN partsupp ps ON l.partkey = ps.partkey
    JOIN part p ON ps.partkey = p.p_partkey
    GROUP BY ps.partkey, p.p_name
    ORDER BY total_quantity DESC
    LIMIT 10
)
SELECT 
    tc.c_name, 
    tc.total_spent, 
    pp.p_name, 
    pp.total_quantity
FROM TopCustomers tc
JOIN PopularParts pp ON tc.custkey = pp.partkey
ORDER BY tc.total_spent DESC, pp.total_quantity DESC;
