WITH RecursiveSupplier AS (
    SELECT s.s_suppkey AS suppkey, s.s_name AS supp_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), 

AveragePartPrice AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),

FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),

StringConcat AS (
    SELECT CONCAT_WS(', ', c.c_name, r.r_name) AS customer_region, 
           COUNT(DISTINCT c.c_custkey) AS cust_count
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY customer_region
    HAVING cust_count > 5
)

SELECT p.p_partkey, p.p_name, p.p_retailprice, rp.suppkey, rp.supp_name, 
       COALESCE(a.avg_supplycost, 0) AS avg_supplycost,
       f.o_orderkey, f.o_orderstatus,
       (
           SELECT COUNT(*) 
           FROM lineitem l 
           WHERE l.l_orderkey = f.o_orderkey AND l.l_returnflag = 'N'
       ) AS num_line_items,
       MAX(s.cust_count) OVER () AS max_customers
FROM part p
LEFT JOIN RecursiveSupplier rp ON p.p_partkey = rp.suppkey
INNER JOIN AveragePartPrice a ON p.p_partkey = a.ps_partkey
JOIN FilteredOrders f ON f.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey LIMIT 1)
FULL OUTER JOIN StringConcat s ON s.customer_region LIKE CONCAT('%', p.p_name, '%')
WHERE p.p_size BETWEEN 10 AND 20 
      AND (p.p_retailprice < 25.00 OR p.p_comment IS NULL)
ORDER BY p.p_partkey, rp.rn DESC NULLS LAST;
