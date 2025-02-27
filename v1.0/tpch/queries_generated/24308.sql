WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available 
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
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
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (
            SELECT AVG(o2.o_totalprice)
            FROM orders o2
            WHERE o2.o_orderstatus = 'O'
        )
)
SELECT 
    r.r_name,
    ps.s_name,
    p.p_name,
    COALESCE(s.rank, 0) AS supplier_rank,
    COALESCE(cp.order_count, 0) AS customer_orders,
    COALESCE(cp.total_spent, 0) AS customer_spent,
    AVG(lp.l_extendedprice * (1 - lp.l_discount)) OVER (PARTITION BY p.p_partkey) AS avg_price_after_discount
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey 
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    lineitem lp ON s.s_suppkey = lp.l_suppkey
INNER JOIN 
    AvailableParts p ON lp.l_partkey = p.p_partkey
LEFT JOIN 
    CustomerOrderStats cp ON cp.c_custkey = 
        (SELECT c.c_custkey 
         FROM customer c 
         WHERE c.c_nationkey = n.n_nationkey 
         ORDER BY c.c_acctbal DESC
         LIMIT 1)
WHERE 
    r.r_name IS NOT NULL 
    AND p.total_available > 0
ORDER BY 
    r.r_name, supplier_rank DESC, customer_orders DESC;
