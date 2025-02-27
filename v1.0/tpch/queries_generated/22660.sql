WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'P')
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL 
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 1000
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_shipmode IN ('AIR', 'TRUCK')
    GROUP BY l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_totalprice,
    d.total_parts,
    s.avg_supply_cost,
    c.total_spent,
    c.total_orders,
    CASE 
        WHEN o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2) THEN 'Above Average'
        ELSE 'Below Average'
    END AS price_category,
    COALESCE(ARRAY_AGG(DISTINCT l.l_shipmode) FILTER (WHERE l.l_shipmode IS NOT NULL), '{}') AS shipping_modes,
    COUNT(DISTINCT l.l_linenumber) AS distinct_line_items
FROM RankedOrders o
LEFT JOIN SupplierSummary d ON d.total_parts > 5
JOIN CustomerSales c ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE o.order_rank <= 10 
AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY o.o_orderkey, o.o_totalprice, d.total_parts, s.avg_supply_cost, c.total_spent, c.total_orders
ORDER BY o.o_orderkey DESC
LIMIT 100;
