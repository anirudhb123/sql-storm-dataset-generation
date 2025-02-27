WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT oh.o_orderkey, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') LIMIT 1)
    WHERE oh.order_level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
LineItemData AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value, l.l_shipdate
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_shipdate
)
SELECT 
    c.c_name,
    co.total_spent,
    COUNT(DISTINCT oh.o_orderkey) AS num_orders,
    COALESCE(lp.total_line_value, 0) AS total_line_value,
    sp.total_supply_cost AS supplier_cost,
    RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
FROM customer c
LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN OrderHierarchy oh ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = oh.o_orderkey LIMIT 1)
LEFT JOIN LineItemData lp ON lp.l_orderkey = oh.o_orderkey
LEFT JOIN SupplierParts sp ON sp.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey WHERE p.p_brand = 'Brand#12' LIMIT 1)
WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
GROUP BY c.c_name, co.total_spent, lp.total_line_value, sp.total_supply_cost
ORDER BY customer_rank, c.c_name;