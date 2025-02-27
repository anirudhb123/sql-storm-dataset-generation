WITH SupplierAggregates AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_per_nation
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING SUM(o.o_totalprice) > 0
),
HighValueSuppliers AS (
    SELECT 
        sa.s_suppkey, 
        sa.s_name 
    FROM SupplierAggregates sa 
    WHERE sa.total_cost > 100000 
    OR sa.avg_acct_balance > 5000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        l.l_partkey, 
        l.l_quantity, 
        l.l_extendedprice, 
        l.l_discount,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    r.r_name AS region_name,
    co.c_name AS customer_name,
    co.total_orders,
    co.total_spent,
    ss.s_name AS supplier_name,
    COUNT(DISTINCT ro.o_orderkey) AS recent_order_count,
    SUM(ro.l_extendedprice * (1 - ro.l_discount)) AS recent_sales
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer co ON n.n_nationkey = co.c_nationkey
LEFT JOIN RecentOrders ro ON co.c_custkey = ro.o_orderkey
LEFT JOIN HighValueSuppliers ss ON ro.l_partkey = ss.s_suppkey
WHERE co.rank_per_nation <= 5
GROUP BY r.r_name, co.c_name, ss.s_name
ORDER BY region_name, customer_name;
