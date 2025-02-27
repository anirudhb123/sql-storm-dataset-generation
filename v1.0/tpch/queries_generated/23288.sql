WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND n.n_name LIKE 'A%'  
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_avail
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)

SELECT 
    p.p_name, 
    r.r_name, 
    c.total_spent, 
    s.s_name, 
    CASE 
        WHEN c.total_spent IS NULL THEN 'No Orders' 
        ELSE 'Active Customer' 
    END AS customer_status,
    COALESCE(AVG(RANKED.rnk), 0) AS avg_supplier_rank
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN 
    region r ON s.r_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders c ON c.c_custkey = (
        SELECT 
            o.o_custkey 
        FROM 
            orders o 
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE 
            l.l_partkey = p.p_partkey 
            AND l.l_quantity > 50
        ORDER BY 
            o.o_orderdate DESC 
        LIMIT 1
    )
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00
  AND 
    (sp.total_avail IS NULL OR sp.total_avail > 0)
GROUP BY 
    p.p_name, r.r_name, c.total_spent, s.s_name
ORDER BY 
    p.p_partkey DESC
LIMIT 10;
