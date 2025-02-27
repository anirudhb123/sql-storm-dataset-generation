WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS sup_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TopProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS product_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_name,
    n.n_name AS supplier_nation,
    tp.p_name,
    tp.total_cost,
    rs.s_name AS top_supplier,
    CASE 
        WHEN o.o_totalprice > 1000 THEN 'High Value Order'
        ELSE 'Regular Order'
    END AS order_value_category,
    COALESCE(CAST(AVG(l.l_discount) OVER (PARTITION BY l.l_shipmode) AS DECIMAL(12, 2)), 0) AS avg_discount,
    CASE 
        WHEN COUNT(DISTINCT l.l_orderkey) = 0 THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey AND rs.sup_rank = 1
JOIN 
    TopProducts tp ON l.l_partkey = tp.p_partkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= DATE '2023-01-01'
    AND l.l_returnflag = 'N'
    AND tp.product_rank <= 10
ORDER BY 
    c.c_name, tp.total_cost DESC;
