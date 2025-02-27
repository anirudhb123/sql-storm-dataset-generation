WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
SuppliersProfit AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        ps.ps_suppkey
),
MaxRevenueSupplier AS (
    SELECT 
        sp.ps_suppkey,
        sp.total_revenue,
        ROW_NUMBER() OVER (ORDER BY sp.total_revenue DESC) AS revenue_rank
    FROM 
        SuppliersProfit sp
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category,
        STRING_AGG(ps.ps_comment, ', ') AS supplier_comments
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_size
)
SELECT 
    rc.c_custkey,
    rc.c_name,
    rc.total_spent,
    p.p_partkey,
    p.p_name,
    p.size_category,
    COALESCE(mrs.total_revenue, 0) AS supplier_total_revenue,
    mrs.revenue_rank
FROM 
    RankedCustomers rc
LEFT JOIN 
    FilteredParts p ON p.size_category = 'Medium'
LEFT JOIN 
    MaxRevenueSupplier mrs ON mrs.ps_suppkey = (SELECT ps_suppkey FROM SuppliersProfit ORDER BY total_revenue DESC LIMIT 1)
WHERE 
    rc.rank <= 10 AND 
    (p.p_size IS NOT NULL OR p.p_partkey IS NULL)
ORDER BY 
    rc.total_spent DESC, p.p_name;
