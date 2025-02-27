WITH RecursiveCTE AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, total_spent,
           RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM RecursiveCTE c
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey,
           p.p_name, p.p_brand, p.p_retailprice,
           s.s_name, s.s_acctbal, s.s_comment
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
FilteredSuppliers AS (
    SELECT DISTINCT s.n_nationkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    GROUP BY s.n_nationkey
    HAVING COUNT(DISTINCT s.s_suppkey) > 2
)
SELECT RANK() OVER (ORDER BY rc.total_spent DESC) AS customer_rank,
       rc.c_name AS customer_name,
       p.p_name AS part_name,
       ps.ps_supplycost AS supplier_cost,
       COALESCE(ns.supplier_count, 0) AS supplier_count,
       CASE 
           WHEN rg.r_name IS NOT NULL THEN rg.r_name
           ELSE 'Unknown'
       END AS region
FROM RankedCustomers rc
LEFT JOIN PartSupplierDetails ps ON rc.total_spent > ps.ps_supplycost
LEFT JOIN region rg ON ps.ps_suppkey = rg.r_regionkey
LEFT JOIN FilteredSuppliers ns ON ns.n_nationkey = rc.c_custkey
WHERE rc.rank <= 10 
  AND ps.ps_supplycost IS NOT NULL
  AND (rc.c_custkey IS NULL OR rc.c_custkey IS NOT NULL)
ORDER BY rc.total_spent DESC, customer_rank;
