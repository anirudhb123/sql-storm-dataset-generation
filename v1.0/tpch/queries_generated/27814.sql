WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS RankByPrice
    FROM 
        part p
    WHERE 
        p.p_type LIKE '%metal%'
), SupplierParts AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedParts p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'United%')
), CustomerOrders AS (
    SELECT 
        c.c_name,
        c.c_nationkey,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLineItemPrice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, c.c_nationkey, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
), FinalBenchmark AS (
    SELECT 
        sp.s_name,
        cp.c_name,
        sp.p_name,
        sp.ps_availqty,
        cp.TotalLineItemPrice,
        cp.o_orderstatus,
        cp.o_orderdate,
        sp.ps_supplycost,
        p.RankByPrice
    FROM 
        SupplierParts sp
    JOIN 
        CustomerOrders cp ON sp.s_nationkey = cp.c_nationkey
    WHERE 
        cp.TotalLineItemPrice > 1000
    ORDER BY 
        sp.ps_supplycost DESC, cp.o_orderdate ASC
)
SELECT 
    COUNT(*) AS TotalRecords,
    AVG(TotalLineItemPrice) AS AverageLineItemPrice,
    MIN(ps_supplycost) AS MinimumSupplyCost,
    MAX(ps_supplycost) AS MaximumSupplyCost
FROM 
    FinalBenchmark
WHERE 
    RankByPrice <= 5;
