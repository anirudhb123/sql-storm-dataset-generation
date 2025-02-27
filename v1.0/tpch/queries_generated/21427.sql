WITH RECURSIVE SupplierCTE AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal > cte.s_acctbal
),
RankedParts AS (
    SELECT p_partkey, p_name, p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY p_retailprice DESC) AS price_rank
    FROM part
    WHERE p_retailprice IS NOT NULL
),
PartSupplier AS (
    SELECT ps.partkey, ps.suppkey, 
           COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost
    FROM partsupp ps
    LEFT JOIN SupplierCTE sc ON ps.ps_suppkey = sc.s_suppkey
    GROUP BY ps.partkey, ps.suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           COUNT(l.l_orderkey) AS line_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
)
SELECT p.p_name, p.p_retailprice, COALESCE(ps.total_supplycost, 0) AS total_supplycost,
       os.total_revenue, os.line_count,
       CASE 
           WHEN os.total_returned > 0 THEN 'Returned'
           ELSE 'Not Returned' 
       END AS return_status,
       RANK() OVER (PARTITION BY os.line_count ORDER BY os.total_revenue DESC) AS revenue_rank
FROM RankedParts p
FULL OUTER JOIN PartSupplier ps ON p.p_partkey = ps.partkey
FULL OUTER JOIN OrderSummary os ON os.line_count > (SELECT AVG(line_count) FROM OrderSummary)
WHERE p.price_rank <= 5
AND (p.p_container IS NULL OR p.p_container LIKE '%BOX%')
ORDER BY os.total_revenue DESC, ps.total_supplycost ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
