WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING total_supply_cost > 10000
),
CustomerPurchaseStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_brand,
    SUM(l.l_quantity) AS total_quantity_sold,
    AVG(l.l_extendedprice) AS avg_price_per_unit,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Demand'
        ELSE 'Low Demand'
    END AS demand_category,
    COUNT(DISTINCT COALESCE(cps.c_custkey, 0)) AS unique_customers
FROM lineitem l
JOIN part p ON l.l_partkey = p.p_partkey
LEFT JOIN CustomerPurchaseStats cps ON l.l_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE order_rank <= 5)
LEFT JOIN SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY p.p_name, p.p_brand
HAVING AVG(l.l_discount) < 0.1
ORDER BY total_quantity_sold DESC, p.p_name
LIMIT 10;
