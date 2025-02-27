WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
SupplierPartData AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 5
),
MaxPart AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        MAX(p.p_retailprice) OVER (PARTITION BY p.p_type) AS max_price_by_type
    FROM part p
)
SELECT 
    r.r_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(total_supply_cost) AS average_supply_cost,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN RankedOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN FrequentCustomers fc ON ro.o_orderkey = fc.c_custkey
LEFT JOIN MaxPart mp ON ps.ps_partkey = mp.p_partkey
WHERE (r.r_name IS NOT NULL OR n.n_name IS NOT NULL)
AND (l.l_tax IS NULL OR l.l_tax > 0.1)
AND mp.max_price_by_type IS NOT NULL
GROUP BY r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY revenue DESC NULLS LAST;
