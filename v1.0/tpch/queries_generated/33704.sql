WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT oh.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey AND o.o_orderstatus = 'O'
),
SupplierAggregates AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
NationalSuppliers AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT ph.r_name, pd.p_name, 
       pd.supplier_count, pd.avg_supply_cost,
       ns.supplier_count AS national_supplier_count,
       ROW_NUMBER() OVER (PARTITION BY ph.r_name ORDER BY pd.sup_count DESC) AS rnk
FROM Region ph
LEFT JOIN PartDetails pd ON pd.p_partkey = (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2)
    ORDER BY ps.ps_supplycost DESC LIMIT 1
)
LEFT JOIN NationalSuppliers ns ON ns.n_name = 'USA'
 WHERE pd.supplier_count > (SELECT COUNT(DISTINCT s.s_suppkey) FROM supplier s WHERE s.s_acctbal IS NOT NULL)
ORDER BY rnk, pd.avg_supply_cost DESC;
