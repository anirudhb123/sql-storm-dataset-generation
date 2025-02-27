WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate > (CURRENT_DATE - INTERVAL '1 year')
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS supplier_rank
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    HAVING COUNT(DISTINCT l.l_orderkey) > 10
),
CustomerDelay AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        MIN(l.l_shipdate - o.o_orderdate) AS min_delay,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(sa.total_avail_qty, 0) AS available_quantity,
    COALESCE(sa.avg_supply_cost, 0) AS average_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM part p
LEFT JOIN SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    (p.p_size IS NULL OR p.p_size > 10) AND 
    (p.p_retailprice BETWEEN 10 AND 100 OR p.p_comment IS NOT NULL)
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    sa.total_avail_qty, 
    sa.avg_supply_cost
HAVING 
    order_count > 10 AND 
    total_revenue > (
        SELECT AVG(total_revenue)
        FROM (
            SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
            FROM lineitem l
            JOIN orders o ON l.l_orderkey = o.o_orderkey
            GROUP BY o.o_orderkey
        ) AS rr
    )
ORDER BY 
    total_revenue DESC, 
    available_quantity ASC 
LIMIT 20;
