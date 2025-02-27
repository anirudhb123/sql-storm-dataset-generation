WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ProductPerformance AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS average_price_after_discount,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        l.l_returnflag = 'N' AND 
        o.o_orderdate >= DATE '2022-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    cs.c_name AS Customer_Name,
    cs.total_orders AS Number_of_Orders,
    cs.total_spent AS Total_Spent,
    pp.p_name AS Product_Name,
    pp.total_quantity_sold AS Quantity_Sold,
    pp.average_price_after_discount AS Avg_Price_After_Discount,
    s.s_name AS Top_Supplier,
    s.s_acctbal AS Supplier_Account_Balance
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    ProductPerformance pp ON cs.total_orders > 0
LEFT JOIN 
    RankedSuppliers s ON s.supplier_rank = 1 AND pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
WHERE 
    cs.total_spent IS NOT NULL AND pp.total_quantity_sold > 0
ORDER BY 
    cs.total_spent DESC, pp.quantity_sold DESC;
