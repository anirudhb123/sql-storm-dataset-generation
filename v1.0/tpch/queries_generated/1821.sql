WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        COALESCE(ps.ps_availqty, 0) AS AvailableQty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_mfgr,
    pd.p_retailprice,
    phc.c_name AS HighValueCustomer,
    rs.s_name AS TopSupplier,
    rs.Rank
FROM 
    PartDetails pd
LEFT JOIN 
    RankedSuppliers rs ON pd.p_partkey = rs.ps_partkey AND rs.Rank = 1
LEFT JOIN 
    HighValueCustomers phc ON phc.TotalSpent > 10000
WHERE 
    pd.AvailableQty > 0
ORDER BY 
    pd.p_retailprice DESC, 
    rs.Rank ASC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
