WITH RECURSIVE PriceAdjustment AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_supplycost * CASE 
            WHEN ps.ps_supplycost IS NULL THEN 0 
            WHEN ps.ps_availqty < 100 THEN 1.1 
            ELSE 1.0 END) AS adjusted_cost
    FROM partsupp ps
    UNION ALL
    SELECT 
        ps2.ps_partkey,
        ps2.ps_suppkey,
        ps2.ps_availqty,
        ps2.ps_supplycost,
        (ps2.ps_supplycost * CASE 
            WHEN ps2.ps_supplycost IS NULL THEN 0 
            WHEN ps2.ps_availqty BETWEEN 100 AND 200 THEN 0.9 
            WHEN ps2.ps_availqty > 200 THEN 0.85 
            ELSE 1.0 END
        ) AS adjusted_cost
    FROM partsupp ps2
    JOIN PriceAdjustment pa ON pa.ps_partkey = ps2.ps_partkey
    WHERE pa.adjusted_cost < ps2.ps_supplycost
),
BestSuppliers AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) as total_avail_qty,
        MIN(pa.adjusted_cost) as min_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN PriceAdjustment pa ON ps.ps_partkey = pa.ps_partkey
    GROUP BY p.p_partkey, s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, o.o_orderkey
)
SELECT 
    b.p_partkey,
    b.s_suppkey,
    b.total_avail_qty,
    c.c_custkey,
    c.lineitem_count,
    c.total_revenue,
    CASE 
        WHEN c.total_revenue IS NULL THEN 'No Orders'
        WHEN c.lineitem_count > 10 THEN 'High Volume'
        ELSE 'Low Volume' 
    END AS order_segment
FROM BestSuppliers b
FULL OUTER JOIN CustomerOrders c ON b.s_suppkey = c.c_custkey
WHERE b.min_cost IS NOT NULL
AND (b.total_avail_qty > 50 OR b.s_suppkey IS NULL)
ORDER BY b.p_partkey, b.s_suppkey, c.c_custkey;
