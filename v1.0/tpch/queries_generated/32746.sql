WITH RECURSIVE Nation_Suppliers AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
Top_Suppliers AS (
    SELECT n.n_name, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier 
        WHERE s_acctbal IS NOT NULL
    )
),
Order_Summary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT n.n_name,
       s.s_name,
       COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
FROM lineitem l 
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN Top_Suppliers s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN Order_Summary os ON os.c_custkey = o.o_custkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY n.n_name, s.s_name
HAVING total_sales > 10000
ORDER BY total_sales DESC;
