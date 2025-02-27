WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS account_rank
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS line_items,
        MAX(CASE WHEN l.l_shipdate > l.l_commitdate THEN 'Late' ELSE 'OnTime' END) AS shipping_status
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    ss.s_name,
    ss.total_parts_supplied,
    ss.total_supply_cost,
    hcc.c_name AS high_value_customer,
    hcc.c_acctbal AS customer_balance,
    od.total_order_value,
    od.line_items,
    od.shipping_status
FROM SupplierStats ss
LEFT JOIN HighValueCustomers hcc ON hcc.account_rank <= 5
JOIN OrderDetails od ON od.total_order_value > 1000
WHERE ss.total_supply_cost > 50000
ORDER BY ss.total_parts_supplied DESC, hcc.c_acctbal DESC;
