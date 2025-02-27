WITH BestSuppliers AS (
    SELECT 
        ps_suppkey,
        SUM(ps_supplycost * ps_availqty) AS total_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps_supplycost * ps_availqty) DESC) AS rank
    FROM partsupp
    GROUP BY ps_suppkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 100.00
    GROUP BY c.c_custkey
),
OrderLineItemStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_lineitem) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) AS open_orders,
    COALESCE(SUM(ols.total_value), 0) AS total_order_value,
    COALESCE(SUM(b.total_cost), 0) AS total_supplier_cost,
    COUNT(DISTINCT cos.c_custkey) AS customer_count
FROM nation n
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN OrderLineItemStats ols ON ols.o_orderkey = o.o_orderkey
LEFT JOIN BestSuppliers b ON c.c_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = b.ps_suppkey LIMIT 1)
WHERE n.r_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'AMERICA')
GROUP BY n.n_name
ORDER BY customer_count DESC, total_order_value DESC
LIMIT 10;
