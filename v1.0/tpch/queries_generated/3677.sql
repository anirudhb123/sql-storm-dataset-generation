WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerSegmentation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
    HAVING 
        SUM(o.o_totalprice) > 5000
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 10
)

SELECT 
    sp.s_name AS Supplier_Name,
    sp.total_available AS Total_Available_Quantity,
    sp.avg_supplycost AS Average_Supply_Cost,
    cs.c_name AS Customer_Name,
    cs.c_mktsegment AS Market_Segment,
    cs.total_spent AS Total_Spent,
    tc.rank AS Customer_Rank
FROM 
    SupplierPerformance sp
FULL OUTER JOIN 
    CustomerSegmentation cs ON sp.total_orders > 0
LEFT JOIN 
    TopCustomers tc ON cs.c_custkey = tc.c_custkey
WHERE 
    sp.total_available IS NOT NULL OR cs.total_spent IS NOT NULL
ORDER BY 
    sp.avg_supplycost DESC, cs.total_spent DESC;
