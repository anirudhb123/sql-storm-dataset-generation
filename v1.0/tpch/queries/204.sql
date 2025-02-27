WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    r.r_name,
    cs.c_custkey,
    cs.c_name,
    COALESCE(cs.order_count, 0) AS order_count,
    COALESCE(cs.total_spent, 0) AS total_spent,
    rs.s_name,
    rs.total_cost,
    CASE 
        WHEN cs.total_spent > 10000 THEN 'High'
        WHEN cs.total_spent BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS spending_category
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey = (SELECT c.c_custkey 
                                           FROM customer c 
                                           WHERE c.c_nationkey = n.n_nationkey 
                                           ORDER BY c.c_acctbal DESC 
                                           LIMIT 1)
WHERE 
    rs.supplier_rank = 1 OR rs.total_cost IS NULL
ORDER BY 
    r.r_name, cs.total_spent DESC;
