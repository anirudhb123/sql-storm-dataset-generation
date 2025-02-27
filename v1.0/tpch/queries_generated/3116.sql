WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal)
            FROM supplier s2
            WHERE s2.s_nationkey = s.s_nationkey
        )
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey,
        c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(cust.c_name, 'No Customers') AS customer_name,
    COALESCE(supp.s_name, 'No Suppliers') AS supplier_name,
    li.line_count,
    li.total_value,
    COUNT(DISTINCT supp.s_suppkey) AS supplier_count,
    px.region_name
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers supp ON ps.ps_suppkey = supp.s_suppkey AND supp.rnk <= 5
LEFT JOIN 
    HighValueCustomers cust ON cust.total_spent > 5000
LEFT JOIN (
    SELECT 
        n.r_regionkey,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
) px ON TRUE
LEFT JOIN 
    LineItemStats li ON li.l_orderkey = ps.ps_partkey
GROUP BY 
    p.p_partkey, p.p_name, cust.c_name, supp.s_name, li.line_count, li.total_value, px.region_name
ORDER BY 
    total_value DESC, supplier_count DESC;
