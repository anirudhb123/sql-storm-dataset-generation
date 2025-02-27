WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_name = (
            SELECT DISTINCT c2.c_name
            FROM customer c2
            WHERE c2.c_nationkey = (
                SELECT n.n_nationkey
                FROM nation n
                WHERE n.n_name = 'FRANCE'
            )
            ORDER BY c2.c_acctbal DESC
            LIMIT 1
        )
    )
    WHERE o.o_orderstatus <> 'O'
),
QualifiedSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey) AS total_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size > 20
),
FinalReport AS (
    SELECT 
        oh.o_orderkey,
        r.p_partkey,
        r.p_name,
        COALESCE(qs.total_supplycost, 0) AS total_supplycost,
        oh.o_orderdate,
        CASE 
            WHEN oh.level = 0 THEN 'Top Level'
            WHEN oh.level = 1 THEN 'Mid Level'
            ELSE 'Base Level'
        END AS order_level
    FROM OrderHierarchy oh
    LEFT JOIN RankedParts r ON r.p_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        WHERE l.l_orderkey = oh.o_orderkey
    )
    LEFT JOIN QualifiedSuppliers qs ON qs.ps_partkey = r.p_partkey
)
SELECT 
    order_level,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    AVG(total_supplycost) AS avg_supplycost,
    SUM(p_retailprice) AS total_retailprice
FROM FinalReport
GROUP BY order_level
ORDER BY total_orders DESC;
