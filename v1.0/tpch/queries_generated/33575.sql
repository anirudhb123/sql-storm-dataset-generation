WITH RECURSIVE ProductHierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, p_comment, 0 AS level
    FROM part
    WHERE p_size IS NOT NULL
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice * 0.9 AS p_retailprice, p.p_comment, ph.level + 1
    FROM part p
    JOIN ProductHierarchy ph ON p.p_size = ph.p_size + 1
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartCosts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderedParts AS (
    SELECT l.l_orderkey, l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(op.total_value), 0) AS total_order_value,
    COALESCE(SUM(spc.total_cost), 0) AS total_supplier_cost,
    ph.level AS hierarchy_level,
    c.total_spent AS customer_spending
FROM part p
LEFT JOIN OrderedParts op ON p.p_partkey = op.l_partkey
LEFT JOIN SupplierPartCosts spc ON p.p_partkey = spc.ps_partkey
LEFT JOIN ProductHierarchy ph ON p.p_partkey = ph.p_partkey
LEFT JOIN CustomerOrders c ON c.total_spent > 1000
GROUP BY p.p_partkey, p.p_name, ph.level, c.total_spent
HAVING total_order_value > 500 OR total_supplier_cost > 1000
ORDER BY total_order_value DESC, p.p_name
LIMIT 100;
