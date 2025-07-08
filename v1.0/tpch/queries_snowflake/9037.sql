WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
),
RevenueSummary AS (
    SELECT 
        r.r_name,
        SUM(ro.total_revenue) AS total_revenue_year
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.o_orderkey IN (SELECT DISTINCT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey))
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    ns.n_name,
    ns.customer_count,
    ns.total_supplier_balance,
    rs.total_revenue_year
FROM 
    NationStats ns
JOIN 
    RevenueSummary rs ON ns.n_name = 'Australia'  
ORDER BY 
    ns.customer_count DESC, rs.total_revenue_year DESC;