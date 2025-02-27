WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
SupplierPartInfo AS (
    SELECT ps.ps_partkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
NationSales AS (
    SELECT n.n_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
),
OrderDetails AS (
    SELECT l.l_orderkey, COUNT(*) AS line_item_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT nh.n_name AS Nation, ns.total_sales, p.p_name AS PartName, 
       COALESCE(sp.total_supply_value, 0) AS SupplierValue, 
       od.line_item_count, od.total_revenue
FROM NationSales ns
FULL OUTER JOIN nation nh ON ns.n_name = nh.n_name
LEFT JOIN SupplierPartInfo sp ON sp.ps_partkey = (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey = (
        SELECT s.s_suppkey 
        FROM supplier s 
        WHERE s.s_name LIKE '%' || nh.n_name || '%'
    )
    LIMIT 1
)
LEFT JOIN part p ON p.p_partkey = sp.ps_partkey
LEFT JOIN OrderDetails od ON od.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_orderkey IN (
        SELECT o_orderkey 
        FROM OrderHierarchy 
        WHERE order_rank = 1
    )
)
WHERE ns.total_sales IS NOT NULL
  AND (p.p_size IS NULL OR p.p_size > 5)
ORDER BY ns.total_sales DESC, SupplierValue DESC;
