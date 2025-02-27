WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
),
TotalRevenue AS (
    SELECT 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2023-12-31'
    GROUP BY l.l_orderkey
),
SupplierEfficiency AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_name
),
CustomerPreferences AS (
    SELECT 
        c.c_nationkey,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment IN ('Corporate', 'Consumer')
    GROUP BY c.c_nationkey
)
SELECT 
    r.r_name,
    COALESCE(preferences.orders_count, 0) AS total_orders,
    SUM(orders.o_totalprice) AS overall_sales,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_extendedprice * (1 - li.l_discount) ELSE 0 END) AS returned_sales,
    COUNT(DISTINCT su.s_name) AS num_suppliers,
    COUNT(DISTINCT p.p_partkey) FILTER (WHERE p.p_size > 10) AS oversized_parts,
    SUM(CASE WHEN s.avg_supply_cost < (SELECT AVG(avg_supply_cost) FROM SupplierEfficiency) THEN 1 ELSE 0 END) AS efficient_suppliers,
    RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS revenue_rank
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem li ON li.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
LEFT JOIN supplier su ON ps.ps_suppkey = su.s_suppkey
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN CustomerPreferences preferences ON preferences.c_nationkey = n.n_nationkey
GROUP BY r.r_name, preferences.orders_count
HAVING SUM(o.o_totalprice) >= (SELECT AVG(o_totalprice) FROM RankedOrders WHERE rank <= 10)
ORDER BY revenue_rank DESC;
