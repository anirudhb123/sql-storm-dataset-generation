WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_totalprice IS NOT NULL
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
ProductSupply AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) >= ALL (SELECT AVG(ps1.ps_availqty) FROM partsupp ps1)
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        lo.l_partkey,
        lo.l_quantity,
        lo.l_extendedprice,
        lo.l_discount,
        lo.l_returnflag,
        lo.l_shipdate,
        lo.l_commitdate,
        lo.l_shipmode,
        CASE 
            WHEN lo.l_discount > 0.1 THEN lo.l_extendedprice * (1 - lo.l_discount) 
            ELSE lo.l_extendedprice 
        END AS adjusted_price
    FROM 
        lineitem lo
    WHERE 
        lo.l_shipdate >= '1997-06-01' AND lo.l_shipdate < '1997-07-01'
),
FinalResults AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        p.p_name,
        SUM(od.adjusted_price) AS total_sales,
        COUNT(DISTINCT HighSup.s_suppkey) AS unique_suppliers
    FROM 
        RankedOrders o
    JOIN 
        OrderDetails od ON o.o_orderkey = od.l_orderkey
    JOIN 
        ProductSupply p ON od.l_partkey = p.p_partkey
    LEFT JOIN 
        HighValueSuppliers HighSup ON o.o_orderkey % HighSup.s_suppkey = 0
    GROUP BY 
        o.o_orderkey, o.o_orderdate, p.p_name
    HAVING 
        SUM(od.adjusted_price) > 100000 OR COUNT(DISTINCT HighSup.s_suppkey) > 5
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.p_name,
    f.total_sales,
    f.unique_suppliers
FROM 
    FinalResults f
ORDER BY 
    f.total_sales DESC
LIMIT 10;