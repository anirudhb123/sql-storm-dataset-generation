WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_partkey) AS total_items
    FROM lineitem l
    WHERE l.l_shipdate <= '2023-10-01' 
    GROUP BY l.l_orderkey
),
TotalRevenue AS (
    SELECT 
        SUM(revenue) AS grand_total_revenue,
        AVG(total_items) AS avg_items_per_order
    FROM LineItemStats
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        cs.order_count, 
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM customer c
    JOIN CustomerStats cs ON c.c_custkey = cs.c_custkey
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
),
PartSupplies AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size IS NOT NULL
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name,
    SUM(l.revenue) AS total_revenue,
    AVG(cs.order_count) AS average_orders_per_customer,
    COUNT(DISTINCT s.s_suppkey) AS active_suppliers,
    MAX(ps.avg_supply_cost) AS max_avg_supply_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN LineItemStats l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
LEFT JOIN CustomerStats cs ON cs.c_custkey IN (SELECT ORDER_ID FROM TopCustomers)
LEFT JOIN PartSupplies ps ON ps.p_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_container IS NOT NULL)
GROUP BY r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY total_revenue DESC;
