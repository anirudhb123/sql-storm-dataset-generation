
WITH Supplier_Summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS Total_Cost,
        COUNT(DISTINCT ps.ps_partkey) AS Total_Parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
Customer_Orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS Total_Orders,
        SUM(o.o_totalprice) AS Total_Spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
Top_Nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS Nation_Rank
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    ss.s_name,
    ss.Total_Cost,
    COALESCE(co.Total_Orders, 0) AS Customer_Orders,
    COALESCE(co.Total_Spent, 0) AS Customer_Spent,
    tn.n_name AS Top_Nation,
    tn.Nation_Rank
FROM 
    Supplier_Summary ss
LEFT JOIN 
    Customer_Orders co ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ss.s_suppkey LIMIT 1)
LEFT JOIN 
    Top_Nations tn ON tn.Nation_Rank <= 5
WHERE 
    ss.Total_Cost > 5000
ORDER BY 
    ss.Total_Cost DESC, Customer_Spent DESC;
