WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        p.p_retailprice,
        CASE 
            WHEN (p.p_retailprice - ps.ps_supplycost) < 0 THEN 'Negative Margin'
            WHEN (p.p_retailprice - ps.ps_supplycost) >= 0 AND (p.p_retailprice - ps.ps_supplycost) < 10 THEN 'Low Margin'
            ELSE 'Healthy Margin'
        END AS MarginStatus
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    ps.p_partkey,
    ps.p_name,
    ps.MarginStatus,
    rs.s_name AS SupplierName,
    rs.s_acctbal,
    CASE 
        WHEN co.OrderRank = 1 THEN 'Most Recent Order'
        ELSE 'Previous Order'
    END AS OrderRecency,
    COALESCE(n.n_name, 'No Nation') AS NationName
FROM 
    CustomerOrders co
LEFT JOIN 
    RankedSuppliers rs ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = co.o_orderkey)
LEFT JOIN 
    PartDetails ps ON ps.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = co.o_orderkey)
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey)
WHERE 
    ps.MarginStatus = 'Healthy Margin'
    OR (rs.SupplierRank <= 3 AND rs.s_acctbal IS NOT NULL)
ORDER BY 
    co.o_orderdate DESC, 
    co.o_totalprice DESC;
