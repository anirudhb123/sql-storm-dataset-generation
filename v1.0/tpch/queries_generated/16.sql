WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0 
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(o.o_orderkey) AS TotalOrders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0 AND 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
SupplierDetails AS (
    SELECT 
        rs.s_name,
        rs.s_acctbal,
        p.p_name,
        rs.SupplierRank,
        COALESCE(pd.TotalSpent, 0) AS TotalSpentByCustomer
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        CustomerOrders pd ON rs.s_suppkey = pd.c_custkey
    JOIN 
        partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    sd.s_name,
    sd.p_name,
    sd.s_acctbal,
    sd.SupplierRank,
    SUM(sd.TotalSpentByCustomer) OVER (PARTITION BY sd.s_name) AS TotalSpentByAllCustomers,
    CASE 
        WHEN sd.s_acctbal IS NULL THEN 'No Account Balance'
        WHEN sd.s_acctbal < 1000 THEN 'Low Balance'
        ELSE 'Sufficient Balance'
    END AS AccountBalanceStatus
FROM 
    SupplierDetails sd
WHERE 
    sd.SupplierRank = 1 
ORDER BY 
    sd.TotalSpentByAllCustomers DESC, 
    sd.s_name ASC;
