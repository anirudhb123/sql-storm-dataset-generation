
WITH SupplierOrderSummary AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_quantity) AS avg_quantity_per_order
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        s.s_name
),
NationRegionSummary AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(COALESCE(sos.total_revenue, 0)) AS total_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        SupplierOrderSummary sos ON sos.supplier_name IN (
            SELECT s.s_name
            FROM supplier s
            WHERE s.s_nationkey = n.n_nationkey
        )
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    region_name,
    nation_name,
    customer_count,
    total_revenue,
    RANK() OVER (PARTITION BY region_name ORDER BY total_revenue DESC) AS revenue_rank
FROM 
    NationRegionSummary
ORDER BY 
    region_name, revenue_rank;
