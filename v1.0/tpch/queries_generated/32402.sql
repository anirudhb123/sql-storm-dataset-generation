WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'F' AND oh.level < 10
),
AggregatedLineItems AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_linenumber) AS item_count,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           MAX(ps.ps_supplycost) AS max_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING AVG(ps.ps_availqty) > 100
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING SUM(o.o_totalprice) > 5000
)
SELECT oh.o_orderkey,
       oh.o_orderstatus, 
       oh.o_orderdate,
       COALESCE(al.total_revenue, 0) AS total_revenue,
       fd.c_name AS customer_name,
       sd.s_name AS supplier_name,
       ROW_NUMBER() OVER (ORDER BY oh.o_orderdate DESC) AS order_rank
FROM OrderHierarchy oh
LEFT JOIN AggregatedLineItems al ON oh.o_orderkey = al.l_orderkey
LEFT JOIN FilteredCustomers fd ON fd.total_spent > al.total_revenue
LEFT JOIN SupplierDetails sd ON sd.max_supplycost >
                                (SELECT AVG(ps.ps_supplycost)
                                 FROM partsupp ps
                                 WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20))
WHERE oh.level <= 3
ORDER BY oh.o_orderdate DESC, total_revenue DESC;
