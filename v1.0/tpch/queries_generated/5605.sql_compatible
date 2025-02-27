
WITH SupplierRanking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 50000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    CONCAT(sr.s_name, ' (Rank: ', sr.rank, ')') AS supplier_info,
    hvc.c_name AS customer_name,
    hvc.total_spent AS customer_total_spent,
    COUNT(ro.o_orderkey) AS total_recent_orders,
    SUM(ro.order_value) AS total_recent_order_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierRanking sr ON s.s_suppkey = sr.s_suppkey
JOIN 
    HighValueCustomers hvc ON hvc.c_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey = n.n_nationkey
    )
JOIN 
    RecentOrders ro ON ro.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_custkey = hvc.c_custkey
    )
GROUP BY 
    r.r_name, n.n_name, sr.s_name, sr.rank, hvc.c_name, hvc.total_spent
ORDER BY 
    region, nation, supplier_info DESC;
