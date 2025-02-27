WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 10
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_nationkey, COUNT(l.l_orderkey) AS total_lineitems
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, c.c_nationkey
),
PartStats AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, SUM(ps.ps_availqty) AS total_available_quantity
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
NationPopularity AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
)
SELECT 
    p.p_name,
    COALESCE(o.total_lineitems, 0) AS order_items_count,
    ps.supplier_count,
    ps.total_available_quantity,
    nh.customer_count AS nation_customer_count,
    SH.suppkey AS supplier_hierarchy,
    RANK() OVER (PARTITION BY p.p_type ORDER BY ps.total_available_quantity DESC) AS part_rank
FROM 
    part p
LEFT JOIN PartStats ps ON p.p_partkey = ps.p_partkey
LEFT JOIN OrderSummary o ON p.p_partkey = o.o_orderkey
LEFT JOIN NationPopularity nh ON nh.n_nationkey = o.c_nationkey
LEFT JOIN SupplierHierarchy SH ON SH.s_suppkey = p.p_partkey
WHERE 
    (ps.total_available_quantity IS NOT NULL OR o.total_lineitems > 5)
    AND p.p_retailprice > 20.00
    AND (SH.s_acctbal IS NULL OR SH.s_acctbal > 1000.00)
ORDER BY 
    p.p_name, part_rank DESC;
