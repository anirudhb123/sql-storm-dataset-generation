WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS TotalPartsSupplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInNation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ss.TotalSupplyValue
    FROM 
        supplier s
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.TotalSupplyValue > (SELECT AVG(TotalSupplyValue) FROM SupplierStats)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate > (SELECT DATEADD(day, -365, CURRENT_DATE)) -- last year purchases
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        cs.c_name,
        ss.s_name AS SupplierName,
        ss.TotalSupplyValue,
        co.TotalSpent,
        (co.TotalSpent - ss.TotalSupplyValue) AS ProfitMargin
    FROM 
        HighValueSuppliers ss
    FULL OUTER JOIN 
        CustomerOrders co ON ss.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'CUSTOMER NATION NAME') 
    WHERE 
        (ProfitMargin < 0 OR ProfitMargin IS NULL) -- interesting corner case
)
SELECT 
    r.*,
    CASE 
        WHEN r.TotalSupplyValue IS NULL THEN 'No Supply'
        ELSE 'Active Supplier'
    END AS SupplierStatus,
    CONCAT(r.c_name, ' - ', r.SupplierName) AS CustomerSupplierRelation
FROM 
    FinalReport r
WHERE 
    r.ProfitMargin IS NOT NULL 
    OR r.SupplierName IS NULL
ORDER BY 
    r.TotalSupplyValue DESC, r.TotalSpent ASC
LIMIT 100;
