WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
HighSpenders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        os.total_orders,
        os.total_spent,
        os.avg_order_value
    FROM 
        customer c
    JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    WHERE 
        os.total_spent > (SELECT AVG(total_spent) FROM OrderSummary)
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(s.s_name, 'No supplier') AS supplier_name,
    hs.c_name AS high_spender_name,
    hs.total_spent AS high_spender_spent,
    CASE 
        WHEN p.p_size IS NULL THEN 'Unknown Size'
        ELSE CAST(p.p_size AS VARCHAR)
    END AS part_size,
    COUNT(l.l_orderkey) AS total_lines,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_discounted_revenue,
    COUNT(DISTINCT l.l_orderkey) AS unique_orders
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.supplier_rank = 1
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    HighSpenders hs ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hs.c_custkey)
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00
GROUP BY 
    p.p_name, p.p_retailprice, s.s_name, hs.c_name, hs.total_spent, p.p_size
HAVING 
    TOTAL_LINES > 5 AND (SUM(l.l_tax) IS NULL OR SUM(l.l_tax) > 0.00)
ORDER BY 
    p.p_retailprice DESC;
