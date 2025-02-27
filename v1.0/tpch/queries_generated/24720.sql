WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
), 
PartSupplierJoin AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS TotalCost
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
FinalSelection AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.TotalCost), 0) AS TotalSupplierCost,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        STRING_AGG(DISTINCT CASE WHEN rnk <= 3 THEN s_name END, ', ') AS TopSuppliers
    FROM 
        part p
    LEFT JOIN 
        PartSupplierJoin ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    LEFT JOIN 
        FilteredOrders o ON o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderdate <= o.o_orderdate)
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.TotalSupplierCost,
    f.TotalOrders,
    f.TopSuppliers,
    CASE 
        WHEN f.TotalOrders = 0 THEN 'No Orders' 
        ELSE 'Has Orders'
    END AS OrderStatus,
    CASE 
        WHEN f.TotalSupplierCost IS NULL THEN 'Cost Unknown'
        ELSE CONCAT('Cost: ', f.TotalSupplierCost)
    END AS SupplierCostStatus
FROM 
    FinalSelection f
WHERE 
    f.TotalOrders > 0 OR f.TotalSupplierCost IS NOT NULL
ORDER BY 
    f.TotalSupplierCost DESC, f.p_name;
