
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal * 0.9, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
    WHERE ch.level < 5
),
MedianPrice AS (
    SELECT 
        p.p_partkey,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ps.ps_supplycost) AS median_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS average_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    ch.c_name,
    ch.level,
    COALESCE(os.order_rank, 0) AS order_rank,
    CASE 
        WHEN ss.average_avail_qty IS NULL THEN 'No Supply'
        ELSE 'In Stock'
    END AS stock_status,
    mp.median_cost
FROM CustomerHierarchy ch
LEFT JOIN OrderDetails os ON ch.c_custkey = os.o_orderkey
LEFT JOIN SupplierStats ss ON os.o_orderkey = ss.s_suppkey
LEFT JOIN MedianPrice mp ON ss.s_suppkey = mp.p_partkey
WHERE 
    (NOT EXISTS (
        SELECT 1 
        FROM customer c2 
        WHERE c2.c_acctbal < 0 
        AND c2.c_custkey = ch.c_custkey
    ) OR ch.level = 1)
    AND (mp.median_cost IS NOT NULL OR ss.total_supply_cost IS NOT NULL)
ORDER BY ch.level, COALESCE(os.total_revenue, 0) DESC NULLS LAST;
