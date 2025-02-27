WITH RECURSIVE DateRange AS (
    SELECT MIN(o_orderdate) AS start_date, MAX(o_orderdate) AS end_date
    FROM orders
    UNION ALL
    SELECT DATE_ADD(start_date, INTERVAL 1 DAY), end_date
    FROM DateRange
    WHERE start_date < end_date
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
),
LineItemAnalytics AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_discount,
        l.l_extendedprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY l.l_orderkey) AS total_discounted_price,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS linenum
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(DISTINCT l.l_suppkey) AS num_suppliers,
        SUM(l.total_discounted_price) AS total_value,
        RANK() OVER (ORDER BY SUM(l.total_discounted_price) DESC) AS order_rank
    FROM orders o
    JOIN LineItemAnalytics l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_discount) AS total_discount,
    AVG(o.total_value) AS avg_order_value,
    (SELECT AVG(total_value) FROM OrderStats WHERE total_value > 1000) AS avg_high_value_order,
    t.s_name AS top_supplier,
    MAX(o.o_orderdate) AS latest_order_date
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN LineItemAnalytics l ON o.o_orderkey = l.l_orderkey
JOIN TopSuppliers t ON l.l_suppkey = t.s_suppkey
WHERE o.o_orderdate BETWEEN (SELECT MIN(start_date) FROM DateRange) AND (SELECT MAX(end_date) FROM DateRange)
GROUP BY r.r_name, t.s_name
HAVING total_discount IS NOT NULL
ORDER BY customer_count DESC, total_discount DESC;
