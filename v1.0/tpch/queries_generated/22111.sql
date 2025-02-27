WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
        CASE 
            WHEN SUM(l.l_quantity) IS NULL THEN 'No Orders'
            ELSE 'Has Orders'
        END AS order_status
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        STRING_AGG(o.o_comment) AS order_comments
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    ps.ps_supplycost,
    ps.ps_availqty,
    cs.total_spent,
    cs.order_count,
    rs.s_name AS top_supplier,
    rs.rnk
FROM 
    PartSupplierDetails ps
JOIN 
    customer c ON ps.p_partkey = c.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rnk = 1 AND rs.s_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders cs ON cs.total_spent > 1000
WHERE 
    ps.total_quantity = (SELECT MAX(total_quantity) FROM PartSupplierDetails WHERE order_status = 'Has Orders')
    AND (ps.ps_availqty IS NULL OR ps.ps_availqty > 10) 
ORDER BY 
    ps.ps_supplycost DESC, cs.order_count DESC;
