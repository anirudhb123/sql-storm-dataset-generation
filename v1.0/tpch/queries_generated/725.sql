WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
), OrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
), ComprehensiveReport AS (
    SELECT 
        o.o_orderkey,
        os.total_orders,
        os.total_spent,
        l.total_value,
        l.item_count,
        rs.s_name,
        rs.s_acctbal
    FROM 
        OrderSummary os
    JOIN 
        orders o ON os.c_custkey = o.o_custkey
    JOIN 
        LineItemSummary l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        RankedSuppliers rs ON l.item_count > 0 AND rs.rnk = 1
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND 
        (l.total_value IS NOT NULL OR rs.s_acctbal IS NOT NULL)
)
SELECT 
    c.c_name,
    r.r_name,
    COALESCE(cr.total_orders, 0) AS orders_count,
    COALESCE(cr.total_spent, 0.00) AS total_spending,
    cr.total_value,
    cr.s_name AS supplier_name
FROM 
    ComprehensiveReport cr
LEFT JOIN 
    customer c ON cr.o_orderkey IS NOT NULL
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    cr.item_count > 1 OR cr.s_acctbal < 5000.00
ORDER BY 
    total_spent DESC, orders_count ASC;
