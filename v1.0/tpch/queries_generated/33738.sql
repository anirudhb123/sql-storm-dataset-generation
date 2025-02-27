WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as rn
    FROM customer c
    INNER JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
RecentOrders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        SUM(co.o_totalprice) AS total_spent,
        COUNT(co.o_orderkey) AS order_count
    FROM CustomerOrders co
    WHERE co.rn <= 5
    GROUP BY co.c_custkey, co.c_name
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM partsupp ps
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
MaxSupplierCost AS (
    SELECT 
        ps.ps_partkey,
        MAX(total_cost) AS max_cost
    FROM SupplierPartDetails ps
    GROUP BY ps.ps_partkey
)

SELECT 
    r.r_name,
    n.n_name,
    SUM(d.total_spent) AS total_revenue,
    COALESCE(SUM(supplier_data.total_cost), 0) AS total_supplier_cost,
    AVG(d.order_count) AS avg_orders_per_customer,
    MAX(supplier_data.supplier_count) AS max_suppliers_per_part
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN RecentOrders d ON n.n_nationkey = d.c_custkey
LEFT JOIN SupplierPartDetails supplier_data ON supplier_data.ps_partkey IN (
    SELECT p.p_partkey 
    FROM part p 
    WHERE p.p_retailprice > (SELECT max_cost FROM MaxSupplierCost WHERE MaxSupplierCost.ps_partkey = p.p_partkey)
)
WHERE n.n_name IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING total_revenue > 100000
ORDER BY total_revenue DESC, r.r_name ASC;
