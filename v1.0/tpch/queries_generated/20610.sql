WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(year, -2, GETDATE())
), 
SupplierAggregate AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(CASE WHEN SUM(l.l_discount) > 0 THEN SUM(l.l_extendedprice * (1 - l.l_discount)) ELSE SUM(l.l_extendedprice) END, 0) AS net_sales,
    r.r_name AS region,
    ns.total_supply_cost,
    cs.total_orders,
    cs.avg_order_value,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY net_sales DESC) AS sales_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierAggregate ns ON s.s_suppkey = ns.s_suppkey
LEFT JOIN CustomerStats cs ON cs.c_custkey = (
    SELECT TOP 1 c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = n.n_nationkey
    ORDER BY c.c_acctbal DESC
)
WHERE r.r_name IS NOT NULL
    AND (p.p_retailprice IS NOT NULL AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 20))
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, r.r_name, ns.total_supply_cost, cs.total_orders, cs.avg_order_value
HAVING SUM(l.l_quantity) > 1000 OR AVG(l.l_tax) IS NULL
ORDER BY sales_rank, net_sales DESC;
