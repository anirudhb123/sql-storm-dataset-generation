WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, 1 as level
    FROM supplier 
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
ProductStats AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineprice
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT 
    coalesce(r.r_name, 'Unknown') AS region_name,
    ns.n_name,
    CONCAT(ns.n_name, ' Suppliers') AS supplier_info,
    SUM(ps.total_available) AS total_available_qty,
    AVG(ps.avg_price) AS average_product_price,
    COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count,
    MAX(hvo.o_totalprice) AS max_order_value
FROM region r
LEFT JOIN nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = ns.n_nationkey
LEFT JOIN ProductStats ps ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = sh.s_suppkey)
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = (SELECT c_custkey FROM customer WHERE c_nationkey = ns.n_nationkey))
GROUP BY region_name, ns.n_name
ORDER BY total_available_qty DESC, average_product_price ASC;
