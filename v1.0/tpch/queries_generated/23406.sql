WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rnk
    FROM 
        supplier s
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_suppkey) AS UniqueSuppliers,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS RevenueRank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        os.o_orderkey,
        os.TotalRevenue,
        os.o_orderdate,
        CASE 
            WHEN os.UniqueSuppliers > 5 THEN 'High Supplier Diversity'
            WHEN os.UniqueSuppliers IS NULL THEN 'No Suppliers'
            ELSE 'Low Supplier Diversity'
        END AS SupplierDiversity
    FROM 
        OrderSummary os
    WHERE 
        os.RevenueRank <= 10
),
SupplierDetails AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        r.r_name AS Region
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rnk = 1
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.TotalRevenue,
    to.SupplierDiversity,
    COALESCE(sd.s_name, 'Unknown Supplier') AS SupplierName,
    sd.Region
FROM 
    TopOrders to
LEFT JOIN 
    SupplierDetails sd ON to.o_orderkey = sd.s_suppkey
WHERE 
    to.TotalRevenue > (SELECT AVG(TotalRevenue) FROM OrderSummary) * 1.5
ORDER BY 
    to.TotalRevenue DESC, 
    sd.s_acctbal DESC
LIMIT 20;
