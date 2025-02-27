
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey, 
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        COUNT(DISTINCT lo.l_linenumber) AS item_count
    FROM 
        lineitem lo
    WHERE 
        lo.l_returnflag = 'N'
    GROUP BY 
        lo.l_orderkey
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
RegionalSales AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS region_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        n.n_name
)

SELECT 
    r.r_name,
    COALESCE(rs.region_sales, 0) AS total_sales,
    COALESCE(o.order_rank, 0) AS highest_order_rank,
    COALESCE(ss.supplier_value, 0) AS total_supplier_value,
    COALESCE(od.item_count, 0) AS total_items_ordered
FROM 
    region r
LEFT JOIN 
    RegionalSales rs ON r.r_name = rs.n_name
LEFT JOIN 
    RankedOrders o ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = rs.n_name)
LEFT JOIN 
    SupplierStats ss ON ss.ps_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps ORDER BY ps.ps_supplycost DESC LIMIT 1)
LEFT JOIN 
    OrderDetails od ON od.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O' ORDER BY o.o_totalprice DESC LIMIT 1)
ORDER BY 
    total_sales DESC, 
    highest_order_rank DESC;
