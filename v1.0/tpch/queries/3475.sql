
WITH RankedLines AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey
),
SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
QualifiedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        (SELECT COUNT(*) FROM lineitem WHERE l_orderkey = o.o_orderkey) AS item_count
    FROM orders o
    WHERE o.o_orderstatus = 'O' 
      AND o.o_orderdate >= '1997-01-01'
)
SELECT 
    n.n_name,
    COALESCE(SUM(r.total_revenue), 0) AS revenue,
    COALESCE(SUM(s.total_cost), 0) AS supplier_cost,
    AVG(q.item_count) AS avg_items
FROM nation n
LEFT JOIN RankedLines r ON r.l_orderkey IN (SELECT q.o_orderkey FROM QualifiedOrders q WHERE q.o_orderkey = r.l_orderkey)
LEFT JOIN SupplierSales s ON s.s_suppkey = r.l_partkey 
LEFT JOIN QualifiedOrders q ON r.l_orderkey = q.o_orderkey
GROUP BY n.n_name
HAVING AVG(q.item_count) > 2 OR COALESCE(SUM(r.total_revenue), 0) > 10000
ORDER BY revenue DESC, n.n_name;
