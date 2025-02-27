WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    cs.c_name AS Customer_Name,
    cs.order_count AS Total_Orders,
    cs.total_spent AS Total_Spent,
    ps.p_name AS Part_Name,
    ps.supplier_count AS Number_of_Suppliers,
    ss.total_cost AS Supplier_Total_Cost
FROM 
    CustomerOrderSummary cs
CROSS JOIN 
    PartSupplierDetails ps
LEFT JOIN 
    SupplierSummary ss ON ps.supplier_count > 0
WHERE 
    cs.order_count > 5 
    AND cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderSummary) 
    AND ps.supplier_count > 2
ORDER BY 
    cs.total_spent DESC, ps.p_name ASC
LIMIT 10;
