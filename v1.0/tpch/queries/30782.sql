WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > sh.s_acctbal
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
        COUNT(li.l_orderkey) AS item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
NationSupplier AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    ns.nation_name,
    COALESCE(ns.total_acctbal, 0) AS total_account_balance,
    COALESCE(ns.supplier_count, 0) AS total_suppliers,
    os.revenue,
    os.item_count
FROM part p
LEFT JOIN OrderStats os ON p.p_partkey = os.o_orderkey
LEFT JOIN NationSupplier ns ON p.p_brand = ns.nation_name
WHERE p.p_retailprice > 100 AND 
      (os.revenue > 1000 OR os.item_count > 5)
ORDER BY p.p_retailprice DESC, os.revenue ASC
LIMIT 100;
