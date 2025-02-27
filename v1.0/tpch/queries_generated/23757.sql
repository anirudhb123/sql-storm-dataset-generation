WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000 
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        COUNT(o.o_orderkey) > 5
),
MajorLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
AggregateParts AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100 AND 
        CHAR_LENGTH(p.p_comment) > 10
    GROUP BY 
        p.p_partkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS high_value_customer_count,
    SUM(l.total_value) AS total_order_value,
    AVG(COALESCE(NULLIF(ps.total_avail_qty, 0), NULL)) AS avg_avail_per_part,
    s.s_name AS top_supplier
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    HighValueCustomers c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    MajorLineItems l ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
LEFT JOIN 
    AggregateParts ps ON ps.p_partkey IN (SELECT ps2.ps_partkey FROM partsupp ps2 WHERE ps2.ps_availqty > 0)
JOIN 
    RankedSuppliers s ON s.rnk = 1 AND s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps)
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_regionkey, r.r_name, s.s_name
ORDER BY 
    total_order_value DESC, high_value_customer_count ASC;
