WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = n.n_nationkey)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
),
SupplyDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey 
    GROUP BY 
        ps.ps_partkey
),
FilteredRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        (SELECT COUNT(*) FROM nation n WHERE n.n_regionkey = r.r_regionkey) AS nation_count
    FROM 
        region r
    WHERE 
        EXISTS (SELECT 1 FROM supplier s WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey))
)
SELECT 
    f.r_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    SUM(o.total_revenue) AS total_sales,
    SUM(sd.total_supply_cost) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    FilteredRegions f
LEFT JOIN 
    RankedSuppliers s ON f.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
LEFT JOIN 
    OrderDetails o ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p))
LEFT JOIN 
    SupplyDetails sd ON sd.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
GROUP BY 
    f.r_name, s.s_name
HAVING 
    SUM(o.total_revenue) > 10000 
ORDER BY 
    total_sales DESC, f.r_name;
