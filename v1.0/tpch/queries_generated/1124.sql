WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
OrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        c.c_nationkey
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_nationkey
), 
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        p.p_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, p.p_name
)
SELECT 
    r.nation_name,
    COUNT(DISTINCT os.c_custkey) AS customer_count,
    SUM(os.total_spent) AS total_revenue,
    SUM(p_avail.ps_availqty) AS total_avail_qty,
    AVG(rs.s_acctbal) AS avg_supplier_acct_balance,
    CASE 
        WHEN COUNT(DISTINCT rs.s_suppkey) > 5 THEN 'High Supplier Diversity'
        ELSE 'Low Supplier Diversity'
    END AS supplier_diversity
FROM 
    RankedSuppliers rs
FULL OUTER JOIN 
    OrderSummary os ON rs.s_suppkey = os.c_nationkey
LEFT JOIN 
    PartSupplierInfo p_avail ON rs.s_suppkey = p_avail.ps_suppkey
JOIN 
    nation r ON r.r_regionkey = rs.s_nationkey
WHERE 
    rs.rank = 1 
    AND (os.total_spent IS NOT NULL OR os.total_orders > 0)
GROUP BY 
    r.nation_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
