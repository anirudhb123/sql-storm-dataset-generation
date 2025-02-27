WITH ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
supplier_summary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
customer_order_count AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS orders_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        COUNT(o.o_orderkey) > 5
)
SELECT
    p.p_name,
    p.p_retailprice,
    r.r_name AS region_name,
    ss.total_available,
    ss.avg_supply_cost,
    COUNT(co.cust_order_count) AS customer_count,
    RANK() OVER (PARTITION BY r.r_name ORDER BY p.p_retailprice DESC) AS price_rank
FROM
    part p
LEFT JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN
    supplier_summary ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN
    nation n ON ss.s_nationkey = n.n_nationkey
LEFT JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    customer_order_count co ON co.orders_count > 5
WHERE
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND r.r_name IS NOT NULL
GROUP BY
    p.p_name, p.p_retailprice, r.r_name, ss.total_available, ss.avg_supply_cost
HAVING
    COUNT(DISTINCT co.c_custkey) > 3
ORDER BY 
    r.r_name, price_rank;
