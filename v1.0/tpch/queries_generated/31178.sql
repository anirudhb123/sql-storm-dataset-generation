WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
BestCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 100000
),
SupplierDetails AS (
    SELECT ps.ps_partkey, s.s_name, MAX(ps.ps_availqty) AS max_avail_qty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
    GROUP BY ps.ps_partkey, s.s_name
),
PartPrices AS (
    SELECT p.p_partkey, p.p_retailprice, p.p_type, ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
),
HighlightedParts AS (
    SELECT pp.p_partkey, pp.p_retailprice
    FROM PartPrices pp
    WHERE pp.rank <= 5
)
SELECT 
    n.n_name AS nation,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
    COUNT(DISTINCT b.c_custkey) AS customer_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    AVG(sp.total_spent) AS avg_spent_per_cust
FROM lineitem li
JOIN orders o ON li.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN BestCustomers b ON c.c_custkey = b.c_custkey
JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
JOIN SupplierDetails sd ON li.l_partkey = sd.ps_partkey
JOIN HighlightedParts hp ON li.l_partkey = hp.p_partkey
WHERE li.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
AND li.l_returnflag = 'N'
GROUP BY n.n_name
ORDER BY revenue DESC;
