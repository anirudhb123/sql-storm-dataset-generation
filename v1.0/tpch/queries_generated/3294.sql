WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), 
TopSuppliers AS (
    SELECT 
        s.s_nationkey, 
        s.s_name 
    FROM 
        RankedSuppliers s 
    WHERE 
        s.Rank = 1
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice,
        COUNT(l.l_orderkey) AS TotalLineItems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetRevenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_retailprice, 
    COALESCE(ts.s_name, 'No Supplier') AS SupplierName,
    os.TotalLineItems,
    os.NetRevenue,
    CASE 
        WHEN os.NetRevenue IS NULL THEN 'No Revenue'
        WHEN os.NetRevenue < 1000 THEN 'Low Revenue'
        ELSE 'High Revenue'
    END AS RevenueCategory
FROM 
    part p
LEFT JOIN 
    TopSuppliers ts ON p.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = ts.s_nationkey)
    )
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    )
ORDER BY 
    p.p_partkey;
