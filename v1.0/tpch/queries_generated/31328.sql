WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 1 AS hierarchy_level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nh.hierarchy_level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
)
, SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END), 0) AS return_count,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS average_order_price,
    MAX(s.total_cost) AS max_supplier_cost
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN SupplierStats s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps 
                                             WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20)
                                             ORDER BY ps.ps_supplycost DESC LIMIT 1)
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY average_order_price DESC
LIMIT 5;
