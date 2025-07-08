
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
PartSupplierCost AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
FinalSupplier AS (
    SELECT 
        pd.s_name AS Supplier_Name,
        pd.region_name AS Region,
        PC.total_supply_cost AS Total_Supply_Cost,
        OS.total_order_value AS Total_Order_Value,
        ROW_NUMBER() OVER (PARTITION BY pd.region_name ORDER BY PC.total_supply_cost DESC, OS.total_order_value DESC) AS rn
    FROM 
        SupplierDetails pd
    LEFT JOIN 
        PartSupplierCost PC ON pd.s_suppkey = PC.ps_partkey
    LEFT JOIN 
        OrderSummary OS ON OS.o_orderkey IN (
            SELECT 
                l.l_orderkey 
            FROM 
                lineitem l 
            JOIN 
                partsupp ps ON l.l_partkey = ps.ps_partkey 
            WHERE 
                ps.ps_suppkey = pd.s_suppkey 
        )
)
SELECT 
    Supplier_Name,
    Region,
    Total_Supply_Cost,
    Total_Order_Value
FROM 
    FinalSupplier
WHERE 
    rn <= 5
ORDER BY 
    Region, Total_Supply_Cost DESC, Total_Order_Value DESC;
