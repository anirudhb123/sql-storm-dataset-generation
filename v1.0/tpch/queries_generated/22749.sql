WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_accountbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) as ranking,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
), 
BestSupplierPerRegion AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        rs.s_name,
        rs.s_accountbal
    FROM 
        region r
    LEFT JOIN 
        RankedSuppliers rs ON r.r_regionkey = rs.n_nationkey AND rs.ranking = 1
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (
            SELECT 
                AVG(o2.o_totalprice)
            FROM 
                orders o2
            WHERE 
                o2.o_orderdate > DATEADD(year, -1, CURRENT_DATE)
        )
), 
CustomerSupplier AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        HighValueCustomers c
    LEFT JOIN 
        partsupp ps ON ps.ps_availqty > 0
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
), 
CombinedData AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        COALESCE(bs.s_name, 'No Supplier') AS best_supplier,
        COALESCE(bs.s_accountbal, 0) AS supplier_acctbal
    FROM 
        CustomerSupplier cs
    LEFT JOIN 
        BestSupplierPerRegion bs ON cs.s_suppkey = bs.s_suppkey
)

SELECT 
    cd.c_custkey,
    cd.c_name,
    cd.best_supplier,
    cd.supplier_acctbal,
    CASE 
        WHEN cd.supplier_acctbal > 1000 THEN 'High Value'
        WHEN cd.supplier_acctbal IS NULL THEN 'No Account'
        ELSE 'Regular'
    END AS supplier_value_category
FROM 
    CombinedData cd
WHERE 
    cd.c_name IS NOT NULL 
    AND (cd.best_supplier IS NOT NULL OR cd.supplier_acctbal > 500)
ORDER BY 
    cd.supplier_acctbal DESC, 
    cd.c_name ASC;

-- To ensure NULL logic is properly incorporated
SELECT 
    COUNT(*) AS total_customers_with_suppliers
FROM 
    CombinedData
WHERE 
    best_supplier IS NULL 
    AND supplier_acctbal < 1000;
