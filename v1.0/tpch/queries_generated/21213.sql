WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
FilteredSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.TotalSupplyCost
    FROM 
        SupplierDetails sd
    WHERE 
        sd.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
OrderSummary AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        COUNT(DISTINCT li.l_partkey) AS distinct_parts,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        RankedOrders ro
    LEFT JOIN 
        lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE 
        li.l_returnflag = 'N'
    GROUP BY 
        ro.o_orderkey, ro.o_totalprice
)
SELECT 
    os.o_orderkey,
    os.o_totalprice,
    os.distinct_parts,
    os.total_revenue,
    COALESCE(fs.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN os.total_revenue < 1000 THEN 'Low Revenue'
        WHEN os.total_revenue BETWEEN 1000 AND 10000 THEN 'Medium Revenue'
        ELSE 'High Revenue'
    END AS revenue_category
FROM 
    OrderSummary os
LEFT JOIN 
    FilteredSuppliers fs ON os.distinct_parts = (SELECT COUNT(*) FROM parts)
ORDER BY 
    os.o_totalprice DESC, os.o_orderkey
LIMIT 50 OFFSET 0;
