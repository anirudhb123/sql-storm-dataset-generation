
WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rnk
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (ORDER BY AVG(ps.ps_supplycost) DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(DISTINCT ps.ps_partkey) > 10
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        MAX(l.l_shipdate) AS latest_shipdate,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        od.order_total,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY od.order_total DESC) AS rnk
    FROM orders o
    JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
    WHERE o.o_orderstatus = 'F'
    AND od.order_total > (SELECT AVG(order_total) FROM OrderDetails)
)
SELECT 
    co.c_name,
    co.total_spent,
    rs.s_name,
    rs.avg_supply_cost,
    hvo.o_orderkey,
    od.order_total,
    od.latest_shipdate
FROM CustomerOrders co
JOIN RankedSuppliers rs ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
LEFT JOIN HighValueOrders hvo ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = hvo.o_orderkey)
LEFT JOIN OrderDetails od ON hvo.o_orderkey = od.o_orderkey
WHERE co.rnk = 1 AND rs.rnk <= 5
ORDER BY co.total_spent DESC, rs.avg_supply_cost ASC;
