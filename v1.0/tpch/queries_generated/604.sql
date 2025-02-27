WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    si.s_name AS supplier_name,
    si.total_available_qty,
    cs.total_orders,
    cs.total_spent,
    COUNT(DISTINCT ro.o_orderkey) AS distinct_orders,
    ROUND(AVG(ro.o_totalprice), 2) AS avg_order_price,
    MAX(ro.o_totalprice) AS max_order_price
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierInfo si ON si.s_nationkey = n.n_nationkey
LEFT JOIN RankedOrders ro ON ro.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderstatus = 'F' 
      AND o.o_totalprice > 500
)
LEFT JOIN CustomerStats cs ON cs.total_orders > 5
GROUP BY r.r_name, n.n_name, si.s_name, si.total_available_qty, cs.total_orders, cs.total_spent
HAVING SUM(CASE WHEN si.total_available_qty IS NULL THEN 0 ELSE si.total_available_qty END) > 1000
ORDER BY region_name, nation_name, supplier_name;
