WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredSuppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.s_name,
        sr.total_cost
    FROM 
        SupplierRevenue sr
    WHERE 
        sr.total_cost > (SELECT AVG(total_cost) FROM SupplierRevenue)
),
FinalResult AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        r.total_revenue,
        fs.s_name,
        fs.total_cost,
        CASE 
            WHEN r.total_revenue IS NULL THEN 'No Revenue'
            WHEN r.total_revenue < 10000 THEN 'Low Revenue'
            WHEN r.total_revenue BETWEEN 10000 AND 50000 THEN 'Medium Revenue'
            ELSE 'High Revenue'
        END AS revenue_category
    FROM 
        RankedOrders r
    FULL OUTER JOIN 
        FilteredSuppliers fs ON r.revenue_rank = 1
    WHERE 
        r.o_orderstatus = 'F' OR r.o_orderstatus IS NULL
)
SELECT 
    fr.o_orderkey,
    fr.o_orderstatus,
    fr.total_revenue,
    fr.s_name,
    COALESCE(fr.total_cost, 0) AS total_cost,
    LENGTH(fr.s_name) AS supplier_name_length,
    CONCAT('Order ', fr.o_orderkey, ' has a total revenue of ', COALESCE(fr.total_revenue, 0), ' and supplier ', COALESCE(fr.s_name, 'None')) AS order_description
FROM 
    FinalResult fr
ORDER BY 
    fr.total_revenue DESC NULLS LAST
LIMIT 100;
