WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
    WHERE c.c_acctbal > ch.c_acctbal
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_discount DESC) AS discount_rank,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey, l.l_suppkey
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON s.s_suppkey = o.o_orderkey 
    WHERE o.o_orderstatus = 'F' OR o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY s.s_suppkey, s.s_name, r.r_name
)
SELECT p.p_name, ps.total_avail_qty, ps.avg_supply_cost, 
       c.c_name, c.level, 
       li.discount_rank, li.total_price, 
       fs.total_sales
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
JOIN CustomerHierarchy c ON c.c_custkey = ps.ps_suppkey
JOIN RankedLineItems li ON li.l_partkey = p.p_partkey
FULL OUTER JOIN FilteredSuppliers fs ON fs.s_suppkey = li.l_suppkey
WHERE (fs.total_sales IS NOT NULL AND c.level < 3)
   OR (c.c_acctbal IS NULL OR c.c_acctbal < 500)
ORDER BY p.p_name, c.level DESC;
