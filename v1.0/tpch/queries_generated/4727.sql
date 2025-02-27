WITH Supplier_Stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
Order_Amounts AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
High_Value_Orders AS (
    SELECT 
        o.o_orderkey,
        oa.order_total,
        CASE 
            WHEN oa.order_total > 5000 THEN 'HIGH'
            WHEN oa.order_total BETWEEN 1000 AND 5000 THEN 'MEDIUM'
            ELSE 'LOW' 
        END AS order_value_category
    FROM 
        Order_Amounts oa
    JOIN 
        orders o ON o.o_orderkey = oa.o_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nations,
    MAX(ss.total_supply_cost) AS max_supply_cost,
    MIN(ss.avg_supply_cost) AS min_avg_supply_cost,
    AVG(ha.order_total) FILTER (WHERE ha.order_value_category = 'HIGH') AS avg_high_order_total,
    COUNT(DISTINCT ha.o_orderkey) AS total_high_value_orders
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    Supplier_Stats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    High_Value_Orders ha ON ha.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'O'
    )
WHERE 
    ss.total_supply_cost IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name ASC;
