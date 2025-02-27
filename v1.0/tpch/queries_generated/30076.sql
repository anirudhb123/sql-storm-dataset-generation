WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_orderdate, o_totalprice, 0 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) as total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT DISTINCT
    oh.o_orderkey,
    oh.o_orderdate,
    oh.o_totalprice,
    sd.s_name AS supplier_name,
    pi.p_name AS part_name,
    pi.total_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY oh.o_orderkey ORDER BY pi.total_supply_cost DESC) AS rank,
    CASE 
        WHEN pi.total_supply_cost IS NULL THEN 'No Supplier'
        ELSE 'Has Supplier'
    END AS supplier_status
FROM OrderHierarchy oh
LEFT JOIN lineitem l ON oh.o_orderkey = l.l_orderkey
LEFT JOIN SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
LEFT JOIN PartInfo pi ON l.l_partkey = pi.p_partkey
WHERE oh.o_totalprice > 500
AND (sd.nation_name IS NOT NULL OR pi.p_name IS NOT NULL)
ORDER BY oh.o_orderdate DESC, rank ASC;
