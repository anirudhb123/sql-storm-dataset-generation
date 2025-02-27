WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sr.total_revenue,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue sr
    JOIN 
        supplier s ON sr.s_suppkey = s.s_suppkey
    WHERE 
        sr.total_revenue > 0
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    cs.c_custkey,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    COALESCE(ts.total_revenue, 0) AS supplier_revenue,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders' 
        WHEN cs.total_spent > 10000 THEN 'High Value' 
        ELSE 'Low Value' 
    END AS customer_value,
    ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY ts.total_revenue DESC NULLS LAST) AS supplier_rank
FROM 
    TopSuppliers ts
FULL OUTER JOIN 
    CustomerOrderStats cs ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)))
WHERE 
    cs.total_spent IS NOT NULL OR ts.total_revenue IS NOT NULL
ORDER BY 
    ts.total_revenue DESC, cs.total_spent DESC;
