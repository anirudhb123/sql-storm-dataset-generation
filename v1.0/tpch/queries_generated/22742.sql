WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1993-01-01' AND o.o_orderdate < '1994-01-01'
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SuppliersWithHighAvailability AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_availqty) > (
        SELECT AVG(ps2.ps_availqty)
        FROM partsupp ps2
    )
),
LineitemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        COALESCE(l.l_discount, 0) AS applicable_discount,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_rank
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
)
SELECT 
    c.c_name,
    r.r_name,
    COALESCE(SUM(ld.l_extendedprice * (1 - ld.applicable_discount)), 0) AS net_revenue,
    COUNT(DISTINCT lo.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CONCAT('Part ', p.p_name, ' from ', s.s_name) 
              ORDER BY p.p_partkey) AS parts_supplied
FROM HighValueCustomers c
JOIN RankedOrders lo ON c.c_custkey = lo.o_orderkey
LEFT JOIN lineitemDetails ld ON lo.o_orderkey = ld.l_orderkey
JOIN partsupp ps ON ld.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE r.r_name IS NOT NULL
GROUP BY c.c_name, r.r_name
HAVING COUNT(DISTINCT lo.o_orderkey) > 5 AND EXISTS (
    SELECT 1 
    FROM SuppliersWithHighAvailability sh 
    WHERE sh.ps_suppkey = s.s_suppkey AND sh.total_availqty > 100
)
ORDER BY net_revenue DESC, total_orders ASC
LIMIT 10;
