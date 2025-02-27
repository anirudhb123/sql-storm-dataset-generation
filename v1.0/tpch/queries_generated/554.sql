WITH SupplierRanking AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 1000
)
SELECT 
    p.p_name, 
    p.p_brand, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    COALESCE(TR.total_revenue, 0) AS total_revenue,
    COALESCE(TR.total_items, 0) AS total_items,
    S.s_name AS top_supplier
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    TopSuppliers S ON ps.ps_suppkey = S.s_suppkey
LEFT JOIN 
    OrderSummary TR ON TR.o_orderkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o 
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE 
            l.l_partkey = p.p_partkey 
            AND l.l_shipdate <= '2023-10-01'
    )
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_name, p.p_brand, S.s_name, TR.total_revenue, TR.total_items
ORDER BY 
    total_revenue DESC, order_count DESC;
