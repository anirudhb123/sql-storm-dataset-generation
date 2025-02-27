WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_mktsegment = 'BUILDING')
),
part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
distinct_nations AS (
    SELECT DISTINCT n.n_nationkey, n.n_name
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey 
    WHERE s.s_acctbal IS NULL OR s.s_acctbal < 5000
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    p.p_name,
    ps.total_avail_qty,
    ps.total_supply_cost,
    dn.n_name AS supplier_nation
FROM customer_orders co
JOIN lineitem l ON co.o_orderkey = l.l_orderkey
JOIN part p ON l.l_partkey = p.p_partkey
JOIN part_supplier ps ON p.p_partkey = ps.p_partkey
LEFT JOIN distinct_nations dn ON l.l_suppkey = dn.n_nationkey
WHERE co.order_rank = 1
AND COALESCE(l.l_discount, 0) > 0.1
UNION ALL
SELECT 
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    p.p_name,
    ps.total_avail_qty,
    ps.total_supply_cost,
    NULL AS supplier_nation
FROM customer_orders co
JOIN lineitem l ON co.o_orderkey = l.l_orderkey
JOIN part p ON l.l_partkey = p.p_partkey
JOIN part_supplier ps ON p.p_partkey = ps.p_partkey
WHERE co.order_rank = 1
AND l.l_shipdate < DATE '2023-01-01'
ORDER BY co.c_name, co.o_orderkey;
