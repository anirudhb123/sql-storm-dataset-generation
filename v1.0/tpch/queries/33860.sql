WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2
        WHERE s2.s_nationkey IN (
            SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1
        )
    )
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE sh.level < 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.05 AND 0.15
),
FinalResult AS (
    SELECT 
        ch.c_custkey AS customer_id,
        ch.c_name AS customer_name,
        sh.s_name AS supplier_name,
        pl.p_name AS part_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM CustomerOrders ch
    LEFT JOIN orders o ON ch.c_custkey = o.o_custkey
    LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    LEFT JOIN RankedLineItems rli ON li.l_orderkey = rli.l_orderkey
    LEFT JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
    LEFT JOIN part pl ON ps.ps_partkey = pl.p_partkey
    LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    WHERE rli.rank = 1
    GROUP BY ch.c_custkey, ch.c_name, sh.s_name, pl.p_name
    HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 500 AND COUNT(DISTINCT o.o_orderkey) > 2
)
SELECT
    fr.customer_id,
    fr.customer_name,
    fr.supplier_name,
    fr.part_name,
    fr.revenue,
    fr.order_count
FROM FinalResult fr
WHERE fr.revenue IS NOT NULL
ORDER BY fr.revenue DESC, fr.order_count DESC;
