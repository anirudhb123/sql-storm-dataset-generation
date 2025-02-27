
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
), 
TopParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    ORDER BY 
        total_supply_value DESC
    LIMIT 5
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
SupplierPartRevenue AS (
    SELECT 
        si.s_suppkey,
        si.s_name,
        si.nation_name,
        SUM(os.total_revenue) AS supplier_revenue
    FROM 
        SupplierInfo si
    JOIN 
        TopParts tp ON EXISTS (SELECT 1 FROM partsupp WHERE ps_partkey = tp.ps_partkey AND ps_suppkey = si.s_suppkey)
    JOIN 
        OrderSummary os ON EXISTS (SELECT 1 FROM lineitem WHERE l_orderkey = os.o_orderkey AND l_partkey = tp.ps_partkey)
    GROUP BY 
        si.s_suppkey, si.s_name, si.nation_name
)
SELECT 
    sr.s_name AS supp_name,
    sr.nation_name,
    sr.supplier_revenue
FROM 
    SupplierPartRevenue sr
WHERE 
    sr.supplier_revenue > 50000
ORDER BY 
    sr.supplier_revenue DESC;
