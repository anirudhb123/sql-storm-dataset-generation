WITH TotalSales AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '2023-01-01' AND l_shipdate < DATE '2023-12-31'
    GROUP BY 
        l_orderkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 500.00
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
        AND o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, c.c_name
),
RegionStats AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    od.o_orderkey,
    od.o_orderstatus,
    od.c_name,
    ts.total_sales,
    COALESCE(ss.num_parts, 0) AS num_parts,
    rs.supplier_count,
    CASE 
        WHEN od.order_total > 1000 THEN 'High Value Order'
        ELSE 'Standard Order'
    END AS order_type
FROM 
    OrderDetails od
LEFT JOIN 
    TotalSales ts ON od.o_orderkey = ts.l_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (SELECT TOP 1 ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT TOP 1 l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey))
LEFT JOIN 
    RegionStats rs ON rs.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = od.o_custkey))
WHERE 
    od.order_total IS NOT NULL
ORDER BY 
    od.o_orderkey;
