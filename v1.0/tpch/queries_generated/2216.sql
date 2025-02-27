WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
AvailableParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 0
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
CustomerSegments AS (
    SELECT 
        c.c_nationkey, 
        c.c_mktsegment, 
        COUNT(DISTINCT c.c_custkey) AS cust_count
    FROM 
        customer c
    GROUP BY 
        c.c_nationkey, c.c_mktsegment
)
SELECT 
    n.n_name, 
    r.r_name, 
    p.p_name, 
    COALESCE(SUM(CASE WHEN hs.rank = 1 THEN hs.s_acctbal END), 0) AS top_supplier_balance,
    COALESCE(SUM(av.total_available), 0) AS total_available_parts,
    COALESCE(ls.order_value, 0) AS high_value_orders,
    cs.cust_count
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers hs ON n.n_nationkey = hs.s_nationkey AND hs.rank = 1
LEFT JOIN 
    AvailableParts av ON TRUE
LEFT JOIN 
    HighValueOrders ls ON ls.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
LEFT JOIN 
    CustomerSegments cs ON cs.c_nationkey = n.n_nationkey
LEFT JOIN 
    part p ON true
GROUP BY 
    n.n_name, r.r_name, p.p_name, cs.cust_count
ORDER BY 
    n.n_name, r.r_name, p.p_name;
