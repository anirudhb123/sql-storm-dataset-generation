WITH RECURSIVE CustomerRank AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
PriceStats AS (
    SELECT ps.part_price, 
           COUNT(*) AS supplier_count,
           AVG(l.l_discount) AS avg_discount
    FROM (
        SELECT ps.ps_supplycost AS part_price,
               ps.ps_partkey
        FROM partsupp ps
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE s.s_acctbal > 2000.00
    ) ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_supplycost
),
OrderDates AS (
    SELECT o.o_orderkey,
           MIN(o.o_orderdate) AS first_order,
           MAX(o.o_orderdate) AS last_order
    FROM orders o
    GROUP BY o.o_orderkey
),
LineStats AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           SUM(l.l_quantity) AS total_quantity,
           DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT pr.p_partkey) AS parts_count,
    SUM(CASE WHEN cr.rank <= 5 THEN cr.c_acctbal ELSE 0 END) AS top_customers_acctbal,
    ps.part_price AS supplier_price,
    MAX(l.total_sales) AS max_total_sales,
    AVG(COALESCE(ls.total_quantity, 0)) AS avg_quantity
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part pr ON ps.ps_partkey = pr.p_partkey
LEFT JOIN CustomerRank cr ON s.s_nationkey = cr.c_nationkey
LEFT JOIN LineStats l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cr.c_custkey)
LEFT JOIN OrderDates od ON od.o_orderkey = l.l_orderkey
WHERE pr.p_retailprice BETWEEN 10.00 AND 100.00
  AND s.s_acctbal IS NOT NULL
GROUP BY n.n_name, ps.part_price
HAVING COUNT(DISTINCT pr.p_partkey) > 0
ORDER BY nation, supplier_price DESC;
