WITH SupplierCost AS (
    SELECT ps.ps_partkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
TopRegions AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_regionkey, r.r_name
    HAVING COUNT(DISTINCT c.c_custkey) > 10
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(year, -1, GETDATE())
)
SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(sc.total_supply_cost, 0) AS supply_cost,
    COALESCE(co.total_orders, 0) AS customer_orders,
    COALESCE(co.total_spent, 0) AS total_customer_spent,
    tr.r_name AS region_name,
    COUNT(DISTINCT ro.o_orderkey) AS recent_orders_count
FROM part p
LEFT JOIN SupplierCost sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN CustomerOrders co ON co.c_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE n.n_nationkey IN (
        SELECT DISTINCT n.n_nationkey
        FROM nation n
        JOIN TopRegions tr ON n.n_regionkey = tr.n_regionkey
    )
)
LEFT JOIN RankedOrders ro ON ro.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        JOIN nation n ON c.c_nationkey = n.n_nationkey
        WHERE n.n_regionkey = (
            SELECT r.r_regionkey
            FROM region r
            WHERE r.r_name LIKE 'S%'
            LIMIT 1
        )
    )
)
GROUP BY p.p_partkey, p.p_name, sc.total_supply_cost, co.total_orders, co.total_spent, tr.r_name
ORDER BY p.p_partkey;
