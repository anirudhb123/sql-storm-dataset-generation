WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O' -- Only include open orders

    UNION ALL

    SELECT o.orderkey, o.custkey, o.orderstatus, o.totalprice, o.orderdate, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
    WHERE o.o_orderstatus = 'O'
),
AggregatedLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, COUNT(*) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size >= 20
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    rh.o_orderkey,
    rh.o_totalprice,
    cl.total_revenue,
    cl.item_count,
    sp.total_supply_cost,
    sp.supplier_count,
    cu.total_orders,
    cu.total_spent
FROM OrderHierarchy rh
JOIN AggregatedLineItems cl ON rh.o_orderkey = cl.l_orderkey
JOIN SupplierParts sp ON cl.total_revenue > sp.total_supply_cost
JOIN CustomerOrders cu ON rh.o_custkey = cu.c_custkey
WHERE rh.level > 1
AND (rh.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31')
ORDER BY rh.o_orderkey DESC
LIMIT 100;
