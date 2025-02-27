WITH RECURSIVE OrderCTE AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey, ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey, ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate) AS rn
    FROM OrderCTE octe
    JOIN orders o ON o.o_orderkey < octe.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND octe.rn < 10
),
TotalLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FilteredSuppliers AS (
    SELECT DISTINCT s.s_suppkey, s.s_name,
           CASE 
               WHEN s.s_acctbal IS NULL THEN 'Unknown'
               WHEN s.s_acctbal < 0 THEN 'Low Balance'
               ELSE 'Normal'
           END AS balance_status
    FROM supplier s
    WHERE EXISTS (
        SELECT 1
        FROM partsupp ps
        WHERE ps.ps_suppkey = s.s_suppkey AND ps.ps_availqty > 0
    )
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_quantity) AS total_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
FinalOutput AS (
    SELECT o.o_orderkey, o.o_orderdate, COALESCE(l.total_revenue, 0) AS total_revenue,
           COALESCE(d.total_quantity, 0) AS total_quantity,
           CASE 
               WHEN o.o_totalprice IS NULL THEN 'Price Unknown'
               WHEN o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) THEN 'High Value' 
               ELSE 'Standard Value'
           END AS price_category
    FROM OrderCTE o
    LEFT JOIN TotalLineItems l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN OrderDetails d ON o.o_orderkey = d.o_orderkey
),
SupplierRanking AS (
    SELECT fs.s_suppkey, fs.s_name, RANK() OVER (PARTITION BY fs.balance_status ORDER BY SUM(l.l_discount) DESC) AS discount_rank
    FROM FilteredSuppliers fs
    JOIN partsupp ps ON fs.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY fs.s_suppkey, fs.s_name, fs.balance_status
)
SELECT fo.*, sr.s_suppkey, sr.discount_rank
FROM FinalOutput fo
FULL OUTER JOIN SupplierRanking sr ON fo.o_orderkey = sr.s_suppkey
WHERE fo.o_orderdate IS NOT NULL OR sr.s_suppkey IS NOT NULL
ORDER BY fo.o_orderdate DESC NULLS LAST, sr.discount_rank ASC;
