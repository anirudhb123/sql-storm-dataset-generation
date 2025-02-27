WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= (CURRENT_DATE - INTERVAL '1 year')
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerSegmentation AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_mktsegment
),
MaxSpent AS (
    SELECT 
        MAX(total_spent) AS max_spent
    FROM CustomerSegmentation
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        CASE 
            WHEN ps.ps_availqty IS NULL THEN 'Unavailable'
            ELSE CONCAT('Available: ', ps.ps_availqty)
        END AS avail_status
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
PendingReviews AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returned_items
    FROM lineitem l
    WHERE l.l_shipdate > CURRENT_DATE
    GROUP BY l.l_orderkey
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    s.total_avail_qty,
    c.c_mktsegment,
    CASE 
        WHEN c.total_spent >= (SELECT max_spent FROM MaxSpent) THEN 'High Roller'
        ELSE 'Regular'
    END AS customer_type,
    p.p_name,
    p.avail_status,
    COALESCE(p.ps_supplycost, (SELECT MIN(ps.ps_supplycost) FROM partsupp ps)) AS lowest_supply_cost,
    pr.line_items,
    pr.revenue
FROM RankedOrders r
LEFT JOIN SupplierInfo s ON s.s_suppkey = 
    (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%widget%') LIMIT 1)
JOIN CustomerSegmentation c ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN PartSupplierDetails p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = s.total_avail_qty)
LEFT JOIN PendingReviews pr ON pr.l_orderkey = r.o_orderkey
WHERE r.price_rank = 1
ORDER BY r.o_totalprice DESC, pr.revenue DESC;
