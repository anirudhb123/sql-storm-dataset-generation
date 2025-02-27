WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        c.c_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2022-12-31'
),
TopOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        c.c_name, 
        c.c_acctbal
    FROM 
        RankedOrders o
    WHERE 
        o.rn <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_acctbal,
        p.p_name, 
        p.p_brand, 
        p.p_retailprice
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FinalReport AS (
    SELECT 
        to.o_orderkey, 
        to.o_totalprice, 
        to.o_orderdate, 
        sd.s_name,
        sd.p_name, 
        sd.p_brand, 
        sd.p_retailprice,
        CASE 
            WHEN to.o_totalprice > 1000 THEN 'High Value'
            ELSE 'Standard Value'
        END AS OrderValueCategory
    FROM 
        TopOrders to
    JOIN 
        SupplierDetails sd ON sd.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = to.o_orderkey)
)
SELECT 
    OrderValueCategory, 
    COUNT(*) as OrderCount, 
    SUM(o_totalprice) as TotalSales,
    AVG(o_totalprice) as AvgSales,
    MIN(o_orderdate) as EarliestOrderDate,
    MAX(o_orderdate) as LatestOrderDate
FROM 
    FinalReport
GROUP BY 
    OrderValueCategory
ORDER BY 
    OrderValueCategory;
