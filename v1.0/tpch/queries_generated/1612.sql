WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as price_rank,
        c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
    AND o.o_orderdate < DATE '2024-01-01'
),
SupplierPartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        s.s_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_suppkey IS NOT NULL
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_orderdate, 
        (ro.o_totalprice - COALESCE(SUM(l.l_discount), 0)) AS adjusted_total
    FROM RankedOrders ro
    LEFT JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
    GROUP BY ro.o_orderkey, ro.o_orderdate, ro.o_totalprice
    HAVING adjusted_total > 1000
)
SELECT 
    hvo.o_orderkey, 
    hvo.o_orderdate,
    hvo.adjusted_total AS total_after_discount,
    spd.p_name,
    spd.ps_availqty,
    spd.ps_supplycost,
    ro.c_mktsegment
FROM HighValueOrders hvo
JOIN SupplierPartDetails spd ON spd.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_supplycost < 20
)
JOIN RankedOrders ro ON hvo.o_orderkey = ro.o_orderkey
ORDER BY hvo.adjusted_total DESC, ro.c_mktsegment;
