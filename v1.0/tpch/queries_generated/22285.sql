WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_retailprice, 1 AS level
    FROM part
    WHERE p_size > 10
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice * 1.1, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_partkey = ph.p_partkey AND ph.level < 5
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CASE WHEN s.s_acctbal IS NULL THEN 'Unknown' ELSE CAST(s.s_acctbal AS VARCHAR) END AS account_balance_str
    FROM supplier s
    WHERE s.s_acctbal < (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
),
ComplexOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_price,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice
),
AggregatedData AS (
    SELECT n.n_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS average_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    GROUP BY n.n_name
)
SELECT ph.p_name, fd.account_balance_str, co.o_orderkey, co.net_price,
       ad.supplier_count, ad.average_supply_cost
FROM PartHierarchy ph
LEFT JOIN FilteredSuppliers fd ON fd.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = ph.p_partkey
)
JOIN ComplexOrders co ON co.o_orderkey IN (
    SELECT oi.o_orderkey
    FROM orders oi
    WHERE oi.o_orderstatus IN ('O', 'F')
)
FULL OUTER JOIN AggregatedData ad ON ph.p_partkey = ad.supplier_count
WHERE ph.p_retailprice IS NOT NULL AND
      (fd.s_acctbal IS NOT NULL OR ad.average_supply_cost IS NOT NULL)
ORDER BY ph.p_name, fd.account_balance_str;
