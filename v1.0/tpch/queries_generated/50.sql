WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        COUNT(DISTINCT l.l_orderkey) AS total_lineitems
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.region_name,
    SUM(os.total_revenue) AS regional_revenue,
    AVG(os.customer_count) AS average_customers_per_order,
    COUNT(DISTINCT rs.s_suppkey) AS unique_suppliers
FROM 
    OrderSummary os
JOIN 
    CustomerRegion cr ON os.o_orderkey IN (
        SELECT 
            l.l_orderkey
        FROM 
            lineitem l
        WHERE 
            l.l_partkey IN (
                SELECT 
                    ps.ps_partkey
                FROM 
                    partsupp ps
                WHERE 
                    ps.ps_availqty > 0
            ) AND l.l_returnflag = 'N'
    )
LEFT JOIN 
    RankedSuppliers rs ON rs.rnk = 1
GROUP BY 
    cr.region_name
HAVING 
    regional_revenue > (
        SELECT 
            AVG(total_revenue) 
        FROM 
            OrderSummary
    )
ORDER BY 
    regional_revenue DESC;
