WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
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
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_line_items,
        FIRST_VALUE(l.l_shipdate) OVER (PARTITION BY o.o_orderkey ORDER BY l.l_shipdate) AS first_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_name,
    cs.order_count,
    cs.max_order_value,
    ss.total_supply_cost,
    ss.total_parts_supplied,
    CASE 
        WHEN cs.order_count > 5 THEN 'Frequent'
        ELSE 'Infrequent'
    END AS customer_status,
    RANK() OVER (ORDER BY cs.max_order_value DESC) AS order_rank
FROM 
    CustomerOrderCounts cs
LEFT JOIN 
    SupplierStats ss ON ss.total_parts_supplied = cs.order_count
WHERE 
    cs.order_count IS NOT NULL
ORDER BY 
    cs.max_order_value DESC, cs.c_name;
