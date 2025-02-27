WITH RECURSIVE Sales_Rank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
Supplier_Stats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
Top_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
        RANK() OVER (ORDER BY COALESCE(ss.total_supply_cost, 0) DESC) AS supplier_rank
    FROM 
        supplier s
    LEFT JOIN 
        Supplier_Stats ss ON s.s_suppkey = ss.s_suppkey
),
Top_Customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        sr.total_spent,
        sr.rank AS customer_rank
    FROM 
        Sales_Rank sr
    JOIN 
        customer c ON sr.c_custkey = c.c_custkey
    WHERE 
        sr.rank <= 10
),
Final_Report AS (
    SELECT 
        tc.c_name AS top_customer,
        ts.s_name AS top_supplier,
        tc.total_spent,
        ts.total_supply_cost
    FROM 
        Top_Customers tc
    FULL OUTER JOIN 
        Top_Suppliers ts ON tc.customer_rank = ts.supplier_rank
)
SELECT 
    fr.top_customer,
    fr.top_supplier,
    COALESCE(fr.total_spent, 0) AS total_customer_spent,
    COALESCE(fr.total_supply_cost, 0) AS total_supplier_cost,
    CASE 
        WHEN fr.total_customer_spent IS NULL AND fr.total_supply_cost IS NULL THEN 'No Data'
        ELSE 'Data Available'
    END AS data_availability
FROM 
    Final_Report fr
ORDER BY 
    total_customer_spent DESC, total_supplier_cost DESC;
