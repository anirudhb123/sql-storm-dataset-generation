WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        COALESCE(NULLIF(s.s_comment, ''), 'No comment') AS adjusted_comment
    FROM 
        supplier s
),
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 0
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, r.r_name
)
SELECT 
    c.c_name,
    c.order_count,
    p.p_name,
    ap.total_available,
    rs.s_name,
    rs.adjusted_comment,
    hv.order_value,
    CASE WHEN hv.order_value IS NOT NULL THEN 'High Value' ELSE 'Standard' END AS order_type
FROM 
    CustomerDetails c
LEFT JOIN 
    AvailableParts ap ON ap.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey IN (
            SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey
        )
    )
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1 AND rs.s_suppkey IN (
        SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ap.ps_partkey
    )
LEFT JOIN
    HighValueOrders hv ON hv.o_orderkey IN (
        SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey
    )
WHERE 
    (c.order_count > 1 OR (c.order_count = 1 AND c.r_name = 'ASIA'))
ORDER BY 
    c.c_name, order_value DESC NULLS LAST;
