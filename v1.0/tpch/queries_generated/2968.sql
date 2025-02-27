WITH SupplyCostRank AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        ps_availqty, 
        ps_supplycost,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rank
    FROM 
        partsupp
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        p.p_name, 
        sc.ps_supplycost
    FROM 
        supplier s
    JOIN 
        SupplyCostRank sc ON s.s_suppkey = sc.ps_suppkey
    JOIN 
        part p ON p.p_partkey = sc.ps_partkey
    WHERE 
        sc.rank <= 3
), 
CustomerOrder AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    co.c_name AS CustomerName,
    co.o_orderkey AS OrderKey,
    co.o_totalprice AS TotalPrice,
    COALESCE(ts.p_name, 'No Supplier') AS PartName, 
    COALESCE(ts.s_name, 'No Supplier') AS SupplierName,
    COALESCE(ts.ps_supplycost, 0) AS SupplyCost
FROM 
    CustomerOrder co
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey IN (
        SELECT s.s_suppkey 
        FROM TopSuppliers s 
        WHERE s.p_name IN (
            SELECT p.p_name 
            FROM part p 
            WHERE p.p_retailprice > 100.00
        )
    )
WHERE 
    co.rn <= 2
ORDER BY 
    co.o_totalprice DESC, 
    CustomerName, 
    PartName;
