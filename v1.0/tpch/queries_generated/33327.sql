WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size <= 20
),
TotalOrderAmounts AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal 
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    ns.n_name AS nation,
    COUNT(DISTINCT ps.p_partkey) AS part_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    SUM(ta.total_amount) AS total_order_value,
    MAX(sh.level) AS max_supplier_level
FROM nation ns
LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN PartSupplierDetails ps ON s.s_suppkey = ps.s_suppkey
LEFT JOIN TotalOrderAmounts ta ON ta.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM FilteredCustomers c))
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE ps.rn = 1 OR sh.level IS NULL
GROUP BY ns.n_name
ORDER BY total_order_value DESC
LIMIT 10;
