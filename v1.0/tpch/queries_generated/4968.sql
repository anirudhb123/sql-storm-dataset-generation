WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS average_acct_balance,
        COUNT(DISTINCT p.p_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value,
        COUNT(l.l_linenumber) AS total_items
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    ss.s_name AS supplier_name,
    ss.total_supply_cost,
    ss.average_acct_balance,
    ss.parts_supplied,
    la.total_line_item_value,
    la.total_items
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    SupplierSummary ss ON cs.total_orders > 0 
LEFT JOIN 
    LineItemAnalysis la ON cs.last_order_date IS NOT NULL
WHERE 
    ss.total_supply_cost > 10000.00 OR cs.total_spent IS NULL 
ORDER BY 
    cs.total_spent DESC, 
    ss.total_supply_cost ASC
FETCH FIRST 50 ROWS ONLY;
