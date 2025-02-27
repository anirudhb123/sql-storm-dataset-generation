WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O' 
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey 
    WHERE o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
QualifiedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p1.p_retailprice) FROM part p1)
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 2
),
FinalOutput AS (
    SELECT 
        oh.o_orderkey,
        oh.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue,
        SUM(li.l_tax) AS total_tax,
        COUNT(DISTINCT li.l_partkey) AS part_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM OrderHierarchy oh
    JOIN lineitem li ON oh.o_orderkey = li.l_orderkey
    JOIN customer c ON c.c_custkey = oh.o_orderkey
    WHERE li.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' 
    GROUP BY oh.o_orderkey, oh.o_orderdate
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT fs.o_orderkey) AS order_count,
    AVG(fs.net_revenue) AS average_net_revenue,
    SUM(fs.total_tax) AS total_tax_collected,
    SUM(ss.total_supply_cost) AS total_supplier_cost,
    SUM(qp.supplier_count) AS total_qualified_parts
FROM region r 
LEFT JOIN FinalOutput fs ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN customer c ON c.c_nationkey = n.n_nationkey WHERE c.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o))
LEFT JOIN SupplierStats ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN QualifiedParts qp ON qp.p_partkey = ps.ps_partkey)
LEFT JOIN QualifiedParts qp ON 1=1
GROUP BY r.r_name
ORDER BY average_net_revenue DESC;
