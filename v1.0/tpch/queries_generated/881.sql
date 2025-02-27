WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders AS o
),
supplier_part AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp AS ps
    GROUP BY ps.ps_partkey
),
long_shipping AS (
    SELECT 
        l.l_orderkey,
        l.l_shipmode,
        DATEDIFF(l.l_commitdate, l.l_shipdate) AS shipping_days
    FROM lineitem AS l
    WHERE l.l_shipdate < l.l_commitdate
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer AS c
    LEFT JOIN orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    c.c_name,
    c.c_address,
    COALESCE(cs.order_count, 0) AS total_orders,
    COALESCE(cs.total_spent, 0.00) AS total_spent,
    rp.total_available,
    rp.avg_supply_cost,
    ls.l_shipmode,
    COUNT(DISTINCT lo.o_orderkey) AS total_orders_with_delay,
    AVG(ls.shipping_days) AS avg_shipping_delay
FROM customer AS c
LEFT JOIN customer_summary AS cs ON c.c_custkey = cs.c_custkey
LEFT JOIN supplier_part AS rp ON rp.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > 0)
LEFT JOIN long_shipping AS ls ON ls.l_orderkey IN (SELECT lo.o_orderkey FROM orders lo WHERE lo.o_orderstatus = 'F')
WHERE (cs.total_spent > 1000 OR cs.order_count > 5)
GROUP BY c.c_name, c.c_address, rp.total_available, rp.avg_supply_cost, ls.l_shipmode
ORDER BY total_spent DESC, total_orders DESC;
