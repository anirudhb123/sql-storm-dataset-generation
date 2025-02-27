WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank,
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 0 
            ELSE s.s_acctbal 
        END as adjusted_acctbal
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
OrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey
)
SELECT 
    ns.n_name,
    p.p_name,
    COALESCE(SUM(ls.l_extendedprice * (1 - ls.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT os.c_custkey) AS customer_count, 
    AVG(rs.adjusted_acctbal) AS avg_supplier_balance
FROM 
    lineitem ls
LEFT JOIN 
    orders o ON ls.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer os ON o.o_custkey = os.c_custkey
LEFT JOIN 
    part p ON ls.l_partkey = p.p_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier rs ON ps.ps_suppkey = rs.s_suppkey
LEFT JOIN 
    nation ns ON rs.s_nationkey = ns.n_nationkey
WHERE 
    rs.supp_rank = 1 AND 
    (ls.l_shipdate >= CURRENT_DATE - INTERVAL '30 days' OR ls.l_returnflag = 'R')
GROUP BY 
    ns.n_name, p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
