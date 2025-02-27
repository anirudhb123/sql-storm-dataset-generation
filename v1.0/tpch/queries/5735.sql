
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_orderdate, 
        ro.o_totalprice
    FROM RankedOrders ro
    WHERE ro.rank_price <= 10
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        hvo.o_orderkey, 
        hvo.o_orderdate, 
        hvo.o_totalprice
    FROM customer c
    INNER JOIN HighValueOrders hvo ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = hvo.o_orderkey)
),
SupplierPartDetails AS (
    SELECT 
        s.s_name, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    INNER JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_name, p.p_name
),
FinalAnalysis AS (
    SELECT 
        co.c_name AS customer_name, 
        COALESCE(spd.total_available, 0) AS total_part_available, 
        SUM(co.o_totalprice) AS total_order_value
    FROM CustomerOrderDetails co
    LEFT JOIN SupplierPartDetails spd ON co.o_orderkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = spd.s_name))
    GROUP BY co.c_name, spd.total_available
)
SELECT 
    customer_name, 
    total_part_available, 
    total_order_value
FROM FinalAnalysis
WHERE total_order_value > 10000
ORDER BY total_order_value DESC;
