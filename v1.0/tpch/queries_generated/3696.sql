WITH supplier_performance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_item_count,
        AVG(l.l_extendedprice) AS avg_line_price
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderstatus, o.o_orderdate
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE 
            WHEN o.o_orderstatus = 'F' THEN o.o_totalprice 
            ELSE 0 
        END) AS total_filled_orders,
    SUM(op.total_available_qty) AS total_available_qty,
    MAX(op.total_supply_cost) AS max_supply_cost
FROM 
    nation ns
JOIN 
    customer c ON ns.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    supplier_performance op ON op.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey = o.o_orderkey
        )
        ORDER BY ps.ps_availqty DESC 
        LIMIT 1
    )
GROUP BY 
    ns.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_filled_orders DESC, 
    total_customers DESC;
