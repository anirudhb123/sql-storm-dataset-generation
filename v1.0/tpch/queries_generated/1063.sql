WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_line_items,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    s.s_suppkey,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(ss.total_parts, 0) AS total_parts_supplied,
    COALESCE(ss.total_available_quantity, 0) AS available_quantity,
    COALESCE(ss.total_supply_value, 0.00) AS supply_value,
    os.total_order_value,
    os.o_orderdate,
    CASE 
        WHEN os.total_order_value IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    supplier s
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_suppkey = s.s_suppkey
        GROUP BY 
            l.l_orderkey
    )
WHERE 
    ss.total_parts > 5 OR ss.total_parts IS NULL
ORDER BY 
    supplier_name,
    total_order_value DESC
LIMIT 50;
