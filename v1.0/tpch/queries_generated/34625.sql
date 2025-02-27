WITH RECURSIVE CTE_Supplier AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, cs.level + 1
    FROM supplier s
    JOIN CTE_Supplier cs ON s.s_suppkey <> cs.s_suppkey AND s.s_acctbal < cs.s_acctbal
),
PARTS_WITH_SUPPLIERS AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
NATION_REGION_SUM AS (
    SELECT n.n_regionkey, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey
),
ORDER_INFO AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT p.p_name, p.ps_supplycost, n.r_name, o.total_price, r.total_acctbal
FROM PARTS_WITH_SUPPLIERS p
LEFT JOIN nation n ON p.ps_supplycost = (SELECT MAX(ps_supplycost) FROM partsupp)
LEFT JOIN NATION_REGION_SUM r ON n.n_regionkey = r.n_regionkey
JOIN ORDER_INFO o ON o.o_orderkey IN (SELECT l.l_orderkey 
                                        FROM lineitem l 
                                        WHERE l.l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 15))
WHERE p.rn = 1
AND r.total_acctbal IS NOT NULL
ORDER BY o.total_price DESC, p.p_name ASC;
