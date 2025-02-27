WITH RECURSIVE SupplierRank AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
), TopSuppliers AS (
    SELECT * FROM SupplierRank WHERE rank <= 5
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal IS NOT NULL AND 
        c.c_acctbal > 100
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
), AggregatedData AS (
    SELECT 
        r.r_name,
        COALESCE(SUM(t.total_revenue), 0) AS total_supplier_revenue,
        COALESCE(SUM(co.total_spent), 0) AS total_customer_spending
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        TopSuppliers t ON n.n_nationkey = t.s_nationkey
    LEFT JOIN 
        CustomerOrders co ON n.n_nationkey = co.c_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    a.r_name,
    a.total_supplier_revenue,
    a.total_customer_spending,
    CASE 
        WHEN a.total_supplier_revenue > a.total_customer_spending THEN 'Suppliers lead'
        WHEN a.total_supplier_revenue < a.total_customer_spending THEN 'Customers lead'
        ELSE 'Balanced'
    END AS market_lead
FROM 
    AggregatedData a
WHERE 
    a.total_supplier_revenue IS NOT NULL
    OR a.total_customer_spending IS NOT NULL
ORDER BY 
    a.total_supplier_revenue DESC NULLS LAST, 
    a.total_customer_spending DESC NULLS LAST
LIMIT 10;
