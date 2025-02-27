WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = o.o_custkey LIMIT 1)
    WHERE o.o_orderstatus = 'O'
),
TotalLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
)
SELECT
    o.o_orderkey,
    o.o_orderstatus,
    oh.order_level,
    COALESCE(t.total_price, 0) AS order_total_price,
    np.n_name AS supplier_nation,
    sp.total_available AS available_parts,
    ts.s_name AS top_supplier
FROM orders o
LEFT JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
LEFT JOIN TotalLineItems t ON o.o_orderkey = t.l_orderkey
LEFT JOIN supplier s ON s.s_nationkey = (
    SELECT n.n_nationkey
    FROM nation n
    WHERE n.n_name = 'USA'
    LIMIT 1
)
LEFT JOIN SupplierParts sp ON sp.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'Manufacturer#1' LIMIT 1)
LEFT JOIN TopSuppliers ts ON ts.s_suppkey = s.s_suppkey
WHERE o.o_orderdate >= '2023-01-01'
AND order_level > 1
ORDER BY o.o_orderkey, order_level DESC;
