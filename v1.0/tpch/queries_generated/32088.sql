WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC)
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.rank < 10
),
SupplierInfo AS (
    SELECT s.s_name, s.s_acctbal, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, s.s_acctbal
),
PartDetail AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr
)
SELECT oh.*, si.s_name, si.avg_supplycost, pd.p_name, pd.supplier_count
FROM OrderHierarchy oh
LEFT JOIN SupplierInfo si ON oh.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2022-12-31'
    GROUP BY l.l_orderkey
)
LEFT JOIN PartDetail pd ON oh.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        WHERE ps.ps_availqty > 100
    )
)
ORDER BY oh.o_orderdate DESC, si.avg_supplycost ASC
LIMIT 100;
