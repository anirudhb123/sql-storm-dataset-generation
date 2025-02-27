WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank_by_acctbal
    FROM 
        supplier s
), SupplierOrders AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), CustomerAggregates AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)

SELECT 
    r.r_name,
    COUNT(DISTINCT cu.c_custkey) AS total_customers,
    SUM(COALESCE(su.total_revenue, 0)) AS total_supplier_revenue,
    SUM(COALESCE(cu.total_spent, 0)) AS total_customer_spending,
    AVG(su.rank_by_acctbal) AS avg_supplier_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerAggregates cu ON c.c_nationkey = cu.c_nationkey
LEFT JOIN 
    SupplierOrders su ON su.ps_partkey IN (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_size > 10 AND p.p_retailprice < 100
    )
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_supplier_revenue DESC, total_customer_spending ASC;
