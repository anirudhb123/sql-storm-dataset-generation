WITH RECURSIVE PartSupplierHierarchy AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, 1 AS tier
    FROM partsupp ps
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, ph.tier + 1
    FROM partsupp ps
    JOIN PartSupplierHierarchy ph ON ps.ps_partkey = ph.ps_partkey
    WHERE ph.tier < 3
), FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount, 
           l.l_tax, l.l_shipdate, ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS rn
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01'
      AND l.l_shipdate < DATE '1998-01-01'
), SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 
           COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
)
SELECT p.p_name, 
       SUM(COALESCE(li.l_quantity * (1 - li.l_discount), 0)) AS total_revenue,
       AVG(sd.total_supplycost) AS avg_supply_cost,
       MAX(sd.s_acctbal) AS max_supplier_balance,
       STRING_AGG(DISTINCT sd.s_comment, '; ') AS supplier_comments
FROM part p
JOIN FilteredLineItems li ON p.p_partkey = li.l_partkey
LEFT JOIN PartSupplierHierarchy psh ON p.p_partkey = psh.ps_partkey
LEFT JOIN SupplierDetails sd ON psh.ps_suppkey = sd.s_suppkey
WHERE p.p_retailprice > 100
GROUP BY p.p_name
HAVING SUM(li.l_quantity * (1 - li.l_discount)) > 50000
ORDER BY total_revenue DESC
LIMIT 10;