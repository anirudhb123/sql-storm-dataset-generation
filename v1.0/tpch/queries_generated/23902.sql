WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderdate < NOW()
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        cs.c_custkey
    FROM CustomerStats cs
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > 100.00
    GROUP BY p.p_partkey, s.s_suppkey
),
OrdersWithPartDetails AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        CASE WHEN l.l_returnflag = 'Y' THEN 'Returned' ELSE 'Not Returned' END AS return_status
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_quantity > 10
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    AVG(w.l_extendedprice * (1 - w.l_discount)) AS avg_line_price,
    ps.total_available,
    CASE WHEN hc.c_custkey IS NOT NULL THEN 'High Value' ELSE 'Regular' END AS customer_segment
FROM RankedOrders r
LEFT JOIN OrdersWithPartDetails w ON r.o_orderkey = w.o_orderkey
LEFT JOIN PartSupplier ps ON w.l_partkey = ps.p_partkey
LEFT JOIN HighValueCustomers hc ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hc.c_custkey)
GROUP BY r.o_orderkey, r.o_orderdate, r.o_totalprice, ps.total_available, hc.c_custkey
HAVING ps.total_available IS NOT NULL
   OR r.o_orderstatus IS NULL
ORDER BY r.o_totalprice DESC, r.o_orderdate ASC
LIMIT 50;
