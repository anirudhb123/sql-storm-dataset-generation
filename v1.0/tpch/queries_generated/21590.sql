WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank_acctbal,
        p.p_partkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate < CURRENT_DATE AND 
        l.l_returnflag = 'N'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
ActiveOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        CASE
            WHEN COUNT(*) OVER (PARTITION BY o.o_orderkey) > 1 THEN 'MULTIPLE_ITEMS'
            ELSE 'SINGLE_ITEM'
        END AS order_type
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    p.p_name,
    rs.s_name,
    COALESCE(c.total_value, 0) AS total_order_value,
    ao.order_type,
    r.r_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    COUNT(o.o_orderkey) AS order_count
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.p_partkey AND rs.rank_acctbal = 1
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    CustomerOrders c ON p.p_partkey = c.o_orderkey  -- using partkey to join with order key (correlated context)
LEFT JOIN 
    ActiveOrders ao ON c.o_orderkey = ao.o_orderkey
JOIN 
    nation n ON n.n_nationkey = (SELECT DISTINCT n_nationkey FROM supplier s1 WHERE s1.s_suppkey = rs.s_suppkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size IS NOT NULL AND 
    r.r_name IS NOT NULL AND 
    (c.total_value > 1000 OR c.total_value IS NULL)
GROUP BY 
    p.p_name, rs.s_name, c.total_value, ao.order_type, r.r_name
HAVING 
    SUM(ps.ps_supplycost * ps.ps_availqty) > 5000
ORDER BY 
    total_supply_cost DESC NULLS LAST; 
