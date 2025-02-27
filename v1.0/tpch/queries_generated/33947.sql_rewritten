WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '1996-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_orderkey
    WHERE o.o_orderdate >= '1996-01-01'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM part p
    INNER JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1996-01-01' AND l.l_returnflag = 'N'
    GROUP BY p.p_partkey, p.p_name
),
CustomerStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey
)
SELECT 
    oh.o_orderkey, 
    oh.o_orderdate, 
    ps.p_name, 
    ps.avg_price,
    COALESCE(cs.order_count, 0) AS order_count,
    cs.total_spent,
    sd.total_cost
FROM OrderHierarchy oh
LEFT JOIN PartSummary ps ON oh.o_orderkey = ps.p_partkey
LEFT JOIN CustomerStats cs ON cs.order_count = oh.o_orderkey
LEFT JOIN SupplierDetails sd ON sd.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%widget%')
)
WHERE oh.level = 1
ORDER BY oh.o_orderdate DESC, sd.total_cost DESC;