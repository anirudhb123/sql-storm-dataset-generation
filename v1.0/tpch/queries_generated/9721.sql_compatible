
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice
    FROM RankedOrders ro
    WHERE ro.rn <= 10
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_spending
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem lo ON o.o_orderkey = lo.l_orderkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, s.s_name
)
SELECT 
    co.c_name,
    co.total_spending,
    tp.o_orderkey,
    tp.o_orderdate,
    tp.o_totalprice,
    sp.s_name,
    sp.total_cost
FROM TopOrders tp
JOIN CustomerDetails co ON tp.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
JOIN SupplierParts sp ON EXISTS (SELECT 1 FROM lineitem l WHERE l.l_orderkey = tp.o_orderkey AND l.l_partkey = sp.ps_partkey)
WHERE co.total_spending > 10000
ORDER BY co.total_spending DESC, tp.o_totalprice DESC;
