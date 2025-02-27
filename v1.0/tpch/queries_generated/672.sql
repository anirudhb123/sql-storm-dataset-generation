WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
TopSuppliers AS (
    SELECT 
        rs.ps_partkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
), 
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey
) 
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(t.s_acctbal), 0) AS total_supplier_balance,
    COUNT(oi.o_orderkey) AS order_count,
    AVG(oi.total_revenue) OVER (PARTITION BY p.p_partkey) AS avg_revenue,
    RANK() OVER (ORDER BY COALESCE(SUM(t.s_acctbal), 0) DESC) AS supplier_balance_rank
FROM 
    part p
LEFT JOIN 
    TopSuppliers t ON p.p_partkey = t.ps_partkey
LEFT JOIN 
    OrderInfo oi ON oi.total_revenue > 1000
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(oi.o_orderkey) > 0
ORDER BY 
    supplier_balance_rank, total_supplier_balance DESC;
