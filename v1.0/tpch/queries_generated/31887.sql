WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 50)

    UNION ALL

    SELECT sh.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 3
),
CustomerSpending AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY c.c_custkey
), 
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, p.p_retailprice, 
           (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
RankedParts AS (
    SELECT p.partkey, p.p_name, p.profit_margin,
           ROW_NUMBER() OVER (ORDER BY p.profit_margin DESC) AS rank
    FROM PartSupplierInfo p
)
SELECT c.c_name, c.c_acctbal, cs.total_spent, p.p_name, p.profit_margin
FROM customer c
LEFT JOIN CustomerSpending cs ON c.c_custkey = cs.c_custkey
LEFT JOIN RankedParts p ON cs.total_spent IS NOT NULL AND p.rank <= 5
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
ORDER BY c.c_acctbal DESC, cs.total_spent ASC 
LIMIT 10;
