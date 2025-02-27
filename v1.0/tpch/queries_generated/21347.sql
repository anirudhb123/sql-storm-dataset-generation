WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        SUM(ps.ps_availqty) AS total_available,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_container
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    np.p_name,
    COALESCE(cp.total_orders, 0) AS customer_order_count,
    COALESCE(sp.total_revenue, 0) AS supplier_total_revenue,
    np.total_available,
    CASE 
        WHEN np.total_available = 0 THEN 'Out of Stock' 
        ELSE 'In Stock' 
    END AS stock_status
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedParts np ON np.rank = 1
LEFT JOIN 
    CustomerOrders cp ON cp.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN 
    SupplierPerformance sp ON sp.revenue_rank = 1 AND np.p_brand = sp.s_name
WHERE 
    (cp.customer_order_count > 0 OR np.total_available > 0)
    AND r.r_name IS NOT NULL
    AND (sp.total_revenue IS NULL OR sp.total_revenue > 1000)
ORDER BY 
    r.r_name, np.p_name;
