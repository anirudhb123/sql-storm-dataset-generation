WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank_acctbal,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND o.o_totalprice > 1000
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 1
)
SELECT 
    r.region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS high_value_customer_count,
    SUM(CASE WHEN rs.rank_acctbal <= 5 THEN 1 ELSE 0 END) AS top_suppliers_count,
    AVG(COALESCE(rs.order_count, 0)) AS avg_orders_per_supplier
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey
LEFT JOIN 
    HighValueCustomers c ON n.n_nationkey = c.c_custkey
GROUP BY 
    r.region_name, n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0 
    AND SUM(COALESCE(rs.order_count, 0)) > 10
ORDER BY 
    high_value_customer_count DESC, top_suppliers_count ASC;
