WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
CustomerOrderStats AS (
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
) 
SELECT 
    ps.ps_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_quantity_returned,
    COALESCE(MAX(cs.total_spent), 0) AS max_customer_spent,
    COALESCE((
        SELECT AVG(total_spent) 
        FROM CustomerOrderStats 
        WHERE order_count > 5
    ), 0) AS avg_spent_high_engagement,
    s.s_name AS top_supplier
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = ps.ps_suppkey AND s.rnk = 1
LEFT JOIN 
    CustomerOrderStats cs ON cs.c_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_acctbal = (
            SELECT MAX(s_acctbal) 
            FROM supplier s
            WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = s.n_nationkey)
        )
    )
GROUP BY 
    ps.ps_partkey, p.p_name, p.p_retailprice, s.s_name
ORDER BY 
    total_quantity_returned DESC, max_customer_spent DESC;
