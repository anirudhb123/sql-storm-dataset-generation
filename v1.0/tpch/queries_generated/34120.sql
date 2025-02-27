WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 1 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r2.r_regionkey, r2.r_name, rh.level + 1
    FROM region r2
    JOIN RegionHierarchy rh ON r2.r_regionkey = rh.r_regionkey + 1
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
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
SuspiciousOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_comment,
        LAG(o.o_totalprice, 1, 0) OVER (ORDER BY o.o_orderdate) AS previous_price
    FROM orders o
    WHERE o.o_totalprice > 1000
),
HighlightedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        CASE 
            WHEN l.l_discount > 0.2 THEN 'High Discount'
            ELSE 'Regular'
        END AS discount_category
    FROM lineitem l
    WHERE l.l_returnflag IS NULL OR l.l_returnflag = 'N'
)
SELECT 
    rh.r_name AS region,
    cu.c_name AS customer_name,
    COALESCE(SUM(cs.total_spent), 0) AS total_spent,
    COALESCE(SUM(ss.total_supply_value), 0) AS total_supply_value,
    COUNT(DISTINCT lo.l_orderkey) AS total_orders,
    COUNT(DISTINCT hs.l_orderkey) AS suspicious_orders_count,
    AVG(lo.l_quantity) AS average_quantity
FROM RegionHierarchy rh
LEFT JOIN CustomerOrders cs ON cs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = rh.r_regionkey))
LEFT JOIN SupplierStats ss ON ss.parts_supplied > 10
LEFT JOIN HighlightedLineItems lo ON lo.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN SuspiciousOrders hs ON hs.o_orderkey = lo.l_orderkey
WHERE rh.level <= 3
GROUP BY rh.r_name, cu.c_name
ORDER BY total_spent DESC, total_supply_value DESC;
