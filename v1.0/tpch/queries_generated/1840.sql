WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size >= 1 AND p.p_size <= 30
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey, c.c_name
),
MaxOrderValue AS (
    SELECT 
        MAX(total_spent) AS max_spent
    FROM 
        CustomerOrderSummary
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    rs.s_name AS primary_supplier,
    cs.order_count,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent > mv.max_spent THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1
CROSS JOIN 
    MaxOrderValue mv
WHERE 
    NULLIF(cs.total_spent, 0) IS NOT NULL
ORDER BY 
    cs.total_spent DESC
FETCH FIRST 10 ROWS ONLY;
