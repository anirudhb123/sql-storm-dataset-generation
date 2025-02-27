WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
        COUNT(l.l_orderkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerActivity AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(DATEDIFF(o.o_orderdate, LAG(o.o_orderdate) OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate)) 
                FILTER (WHERE o.o_orderdate IS NOT NULL)) AS avg_days_between_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_name,
    ss.s_name,
    cs.total_spent AS customer_spend,
    ss.total_supply_value AS supplier_supply_value,
    CASE 
        WHEN cs.total_orders > 10 THEN 'High'
        WHEN cs.total_orders BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS order_frequency,
    SUM(CASE 
            WHEN cs.total_orders IS NULL THEN 0
            ELSE cs.total_orders
        END) OVER (PARTITION BY cs.c_name ORDER BY cs.total_spent DESC) AS cumulative_orders,
    ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_spent DESC) AS order_rank
FROM 
    CustomerActivity cs
JOIN 
    SupplierStats ss ON cs.total_orders = ss.part_count
WHERE 
    (cs.total_spent IS NOT NULL AND ss.total_supply_value IS NOT NULL)
    OR (cs.total_spent IS NULL AND ss.total_supply_value IS NULL)
ORDER BY 
    cs.total_spent DESC, ss.total_supply_value ASC
LIMIT 100;
