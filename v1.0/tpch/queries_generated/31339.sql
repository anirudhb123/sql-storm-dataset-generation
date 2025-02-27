WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.orderkey,
        c.custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) as rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.orderkey, c.custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        custkey,
        c_name,
        total_spent
    FROM 
        OrderHierarchy
    WHERE 
        rank <= 10
),
SupplierData AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        CASE 
            WHEN SUM(ps.ps_supplycost) IS NULL THEN 0
            ELSE SUM(ps.ps_supplycost)
        END AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
)
SELECT 
    tc.c_name AS Customer_Name,
    tc.total_spent AS Total_Spent,
    sd.total_available AS Total_Available,
    sd.total_supply_cost AS Total_Supply_Cost,
    ROUND(sd.total_supply_cost / NULLIF(sd.total_available, 0), 2) AS Cost_Per_Unit,
    CASE 
        WHEN tc.total_spent > 10000 THEN 'High Value'
        ELSE 'Regular'
    END AS Customer_Type
FROM 
    TopCustomers tc
LEFT JOIN 
    SupplierData sd ON sd.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps ORDER BY RANDOM() LIMIT 1)
ORDER BY 
    tc.total_spent DESC
LIMIT 5;
