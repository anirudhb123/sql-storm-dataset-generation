WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 
           1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_extended_price,
           l.l_returnflag,
           l.l_linestatus
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_returnflag, l.l_linestatus
)
SELECT 
    oh.o_orderkey,
    oh.o_orderdate,
    cs.c_name,
    ss.s_name AS supplier_name,
    ss.total_available,
    ss.total_cost,
    lis.total_extended_price,
    cs.total_orders,
    cs.total_spent,
    COALESCE(lis.l_returnflag, 'N') AS return_flag,
    COALESCE(lis.l_linestatus, 'O') AS line_status,
    oh.level
FROM OrderHierarchy oh
JOIN CustomerStats cs ON oh.o_custkey = cs.c_custkey
LEFT JOIN LineItemStats lis ON oh.o_orderkey = lis.l_orderkey
LEFT JOIN SupplierInfo ss ON ss.s_suppkey = (SELECT ps.ps_suppkey
                                               FROM partsupp ps
                                               JOIN lineitem l ON ps.ps_partkey = l.l_partkey
                                               WHERE l.l_orderkey = oh.o_orderkey
                                               LIMIT 1)
WHERE oh.level <= 3
ORDER BY oh.o_orderdate DESC, cs.total_spent DESC;
