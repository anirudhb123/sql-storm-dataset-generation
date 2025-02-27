WITH SupplierStats AS (
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
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS item_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_available,
        ss.avg_supply_cost,
        ROW_NUMBER() OVER (ORDER BY ss.total_available DESC) AS row_num
    FROM 
        SupplierStats ss
)
SELECT 
    os.o_orderkey,
    os.c_name,
    ts.s_name,
    ts.total_available,
    ts.avg_supply_cost,
    os.total_price,
    (CASE 
        WHEN os.total_price > 1000 THEN 'High Value'
        WHEN os.total_price BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END) AS price_category,
    (SELECT COUNT(DISTINCT l2.l_linenumber)
     FROM lineitem l2
     WHERE l2.l_orderkey = os.o_orderkey) AS total_line_items
FROM 
    OrderSummary os
LEFT JOIN 
    TopSuppliers ts ON os.item_count > 5 AND ts.row_num <= 10
WHERE 
    ts.total_available IS NOT NULL
  AND os.last_order_date = (
        SELECT 
            MAX(o2.o_orderdate) 
        FROM 
            orders o2 
        WHERE 
            o2.o_custkey = os.o_custkey
    )
ORDER BY 
    os.total_price DESC, os.o_orderkey;
