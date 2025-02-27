WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.total_spent,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS customer_rank
    FROM CustomerOrders c
)
SELECT 
    r.r_name AS region_name,
    p.p_type,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    COALESCE(SUM(sp.total_supply_cost), 0) AS total_supplier_cost,
    tc.c_name AS top_customer_name,
    tc.total_spent AS top_customer_spending
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN RankedOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN TopCustomers tc ON tc.customer_rank = 1
WHERE l.l_shipdate >= DATE '2023-01-01' 
AND l.l_shipdate < DATE '2024-01-01'
AND (p.p_brand LIKE 'Brand%')
GROUP BY r.r_name, p.p_type, tc.c_name, tc.total_spent
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC, total_orders DESC;
