WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returns
    FROM 
        supplier s 
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal IS NOT NULL AND
        (l.l_shipmode IN ('AIR', 'TRUCK') OR l.l_returnflag IS NOT NULL)
    GROUP BY 
        s.s_suppkey, s.s_name
), CustomerSpend AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spend,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0 
    GROUP BY 
        c.c_custkey
), RevenueSummary AS (
    SELECT 
        so.s_suppkey,
        so.s_name,
        so.order_count,
        so.total_revenue,
        cs.total_spend,
        cs.order_count AS customer_order_count,
        DENSE_RANK() OVER (ORDER BY so.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders so
    FULL OUTER JOIN 
        CustomerSpend cs ON so.order_count = cs.order_count
)
SELECT 
    r.s_suppkey,
    r.s_name,
    COALESCE(r.total_revenue, 0.00) AS total_revenue,
    COALESCE(r.total_spend, 0.00) AS total_spend,
    COALESCE(r.revenue_rank, 'N/A') AS revenue_rank
FROM 
    RevenueSummary r
WHERE 
    (r.total_revenue IS NOT NULL AND r.total_revenue > (SELECT AVG(total_revenue) FROM SupplierOrders)) 
    OR r.total_spend > (SELECT SUM(o_totalprice) / COUNT(*) FROM orders)
ORDER BY 
    r.total_revenue DESC, r.total_spend DESC;
