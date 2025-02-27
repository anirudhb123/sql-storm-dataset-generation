WITH RECURSIVE SupplyChain AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name, s.s_address, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
),
RegionSales AS (
    SELECT n.n_nationkey, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey
)
SELECT sc.p_partkey, sc.p_name, sc.s_name, sc.ps_supplycost, 
       COALESCE(cs.total_spent, 0) AS total_spent,
       rs.total_sales,
       CASE 
           WHEN rs.total_sales IS NULL THEN 'No Sales'
           WHEN rs.total_sales > 1000 THEN 'High Sales'
           ELSE 'Moderate Sales'
       END AS sales_category
FROM SupplyChain sc
LEFT JOIN CustomerOrders cs ON cs.o_orderkey = (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderdate = (SELECT MAX(o2.o_orderdate) 
                            FROM orders o2 
                            WHERE o2.o_orderdate <= cast('1998-10-01' as date))
    LIMIT 1
)
LEFT JOIN RegionSales rs ON rs.n_nationkey = (
    SELECT DISTINCT n.n_nationkey
    FROM nation n
    WHERE n.n_nationkey = sc.p_partkey % 5  
)
ORDER BY sc.ps_supplycost DESC, total_spent DESC
LIMIT 50;