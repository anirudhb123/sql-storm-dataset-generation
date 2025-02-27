WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available,
        COALESCE(SUM(ps.ps_supplycost), 0.00) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
HighValueCustomers AS (
    SELECT 
        cus.c_custkey,
        cus.c_name,
        cus.total_orders,
        cus.total_spent,
        ROW_NUMBER() OVER (ORDER BY cus.total_spent DESC) AS customer_rank
    FROM CustomerOrderSummary cus
    WHERE cus.total_spent > 10000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderdate < CURRENT_DATE - INTERVAL '30 days' THEN 'Older'
            ELSE 'Recent'
        END AS order_type
    FROM orders o
)
SELECT 
    cus.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    s.s_name AS supplier_name,
    pp.p_name AS part_name,
    rp.total_available,
    rp.total_supply_cost,
    r.region_name,
    r.r_comment
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN HighValueCustomers cus ON o.o_custkey = cus.c_custkey
JOIN SupplierPartDetails rp ON l.l_suppkey = rp.s_suppkey AND l.l_partkey = rp.p_partkey
JOIN nation n ON n.n_nationkey = cu.c_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE l.l_returnflag = 'N' 
GROUP BY cus.c_name, s.s_name, p.p_name, rp.total_available, rp.total_supply_cost, r.region_name, r.r_comment
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY total_revenue DESC
LIMIT 100;
