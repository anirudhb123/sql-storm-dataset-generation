WITH supplier_part_cost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        spc.total_cost
    FROM supplier s
    JOIN supplier_part_cost spc ON s.s_suppkey = spc.s_suppkey
    ORDER BY spc.total_cost DESC
    LIMIT 10
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
order_details AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price,
        MAX(l.l_shipdate) AS last_shipdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    od.o_orderkey,
    od.o_orderstatus,
    od.total_lineitem_price,
    od.last_shipdate
FROM top_suppliers ts
JOIN customer_orders co ON ts.total_cost > (SELECT AVG(total_cost) FROM supplier_part_cost)
JOIN order_details od ON od.total_lineitem_price > 5000
ORDER BY ts.total_cost DESC, co.total_spent DESC, od.last_shipdate DESC;
