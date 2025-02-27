WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        part p ON EXISTS (
            SELECT 1 
            FROM partsupp ps 
            WHERE ps.ps_suppkey = s.s_suppkey AND ps.ps_partkey = p.p_partkey
        )
),
CustomerOrders AS (
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
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > 5000
)
SELECT 
    r.r_name,
    COALESCE(SUM(CASE WHEN ls.l_returnflag = 'R' THEN 1 ELSE 0 END), 0) AS total_returns,
    COALESCE(SUM(ls.l_extendedprice * (1 - ls.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT h.c_custkey) AS high_value_cust_count,
    GROUP_CONCAT(DISTINCT s.s_name) AS supplier_names
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem ls ON ls.l_partkey = p.p_partkey
LEFT JOIN 
    HighValueCustomers h ON h.c_custkey = ls.l_orderkey
WHERE 
    ls.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
