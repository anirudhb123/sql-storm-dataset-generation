WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1996-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = oh.o_orderkey)
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1996-01-01'
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
NationSupplier AS (
    SELECT n.n_nationkey, COUNT(s.s_suppkey) AS supplier_count, SUM(s.s_acctbal) AS total_accounts
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
),
CustomerStats AS (
    SELECT c.c_nationkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    GROUP BY c.c_nationkey
)
SELECT r.r_name, 
       ns.supplier_count, 
       ns.total_accounts, 
       cs.order_count, 
       cs.total_spent,
       p.p_name,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY cs.total_spent DESC) AS rank
FROM region r
LEFT JOIN NationSupplier ns ON r.r_regionkey = ns.n_nationkey
LEFT JOIN CustomerStats cs ON ns.n_nationkey = cs.c_nationkey
LEFT JOIN part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM PartSupplier ps WHERE ps.avg_supply_cost < 100)
WHERE r.r_regionkey IS NOT NULL
ORDER BY r.r_name, rank
LIMIT 100;