
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerRanking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY SUM(os.total_order_value) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        OrderStats os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.customer_rank,
    cs.c_name,
    ss.s_name AS supplier_name,
    ss.total_available_quantity,
    ss.avg_supply_cost,
    CASE 
        WHEN ss.total_available_quantity IS NULL THEN 'No Supplier'
        ELSE 'Available Supplier'
    END AS supplier_status
FROM 
    CustomerRanking cs
LEFT JOIN 
    SupplierStats ss ON cs.c_custkey = (SELECT MAX(c.c_custkey) FROM customer c WHERE c.c_custkey <= cs.c_custkey)
WHERE 
    cs.customer_rank <= 10
ORDER BY 
    cs.customer_rank, ss.avg_supply_cost DESC;
