WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_orderpriority
    FROM orders
    WHERE o_orderdate >= DATE '2023-01-01'
    UNION ALL
    SELECT o1.o_orderkey, o1.o_custkey, o1.o_orderdate, o1.o_orderpriority
    FROM orders o1
    INNER JOIN OrderHierarchy oh ON o1.o_orderkey = oh.o_orderkey + 1
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerAggregates AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_filled
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    COALESCE(ca.total_orders, 0) AS customer_orders,
    COALESCE(sa.total_available, 0) AS total_available_parts,
    r.r_name AS region_name,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS ranking,
    CASE 
        WHEN SUM(l.l_quantity) > 1000 THEN 'High Volume'
        WHEN SUM(l.l_quantity) BETWEEN 500 AND 1000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM lineitem l
JOIN part p ON l.l_partkey = p.p_partkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerAggregates ca ON ca.c_custkey = (SELECT MIN(c_custkey) FROM customer)
LEFT JOIN SupplierStats sa ON sa.s_suppkey = s.s_suppkey
WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY p.p_name, s.s_name, r.r_name, ca.total_orders, sa.total_available
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY r.r_name, total_quantity DESC;
