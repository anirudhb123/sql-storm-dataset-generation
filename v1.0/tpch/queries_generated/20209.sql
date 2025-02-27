WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_per_nation,
        o.o_orderstatus,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            WHEN o.o_orderstatus = 'P' THEN 'Processing'
            ELSE 'Unknown' 
        END AS status_description
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), FilteredOrders AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(ro.o_orderkey) AS total_orders,
        SUM(ro.o_totalprice) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = ro.c_name AND c.c_acctbal IS NOT NULL LIMIT 1)
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rank_per_nation <= 5 AND 
        (ro.o_orderdate BETWEEN '1995-01-01' AND '1997-12-31')
    GROUP BY 
        r.r_name, n.n_name
), SupplierSales AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_orderkey) AS order_count,
        CASE 
            WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) < 1000 THEN 'Low Performer'
            WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 1000 AND 5000 THEN 'Medium Performer'
            ELSE 'High Performer' 
        END AS performance_category
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_suppkey
), CombinedResults AS (
    SELECT 
        fo.region_name,
        fo.nation_name,
        COALESCE(ss.order_count, 0) AS total_orders_by_supplier,
        COALESCE(ss.revenue, 0) AS total_revenue_by_supplier,
        fo.total_orders,
        fo.total_revenue
    FROM 
        FilteredOrders fo
    FULL OUTER JOIN 
        SupplierSales ss ON fo.region_name = ss.region_name OR fo.nation_name = ss.nation_name
)
SELECT 
    *,
    CASE 
        WHEN total_revenue > 0 AND total_revenue_by_supplier > 0 THEN (total_revenue_by_supplier / total_revenue) * 100
        ELSE 0 
    END AS supplier_contribution_percentage
FROM 
    CombinedResults
WHERE 
    (total_orders > 0 OR total_orders_by_supplier > 0)
ORDER BY 
    total_revenue DESC, supplier_contribution_percentage ASC;
