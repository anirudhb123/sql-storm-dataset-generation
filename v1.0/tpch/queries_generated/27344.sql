WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        RANK() OVER (PARTITION BY p.p_type ORDER BY LENGTH(p.p_comment) DESC) AS rank
    FROM 
        part p
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CONCAT("Customer: ", c.c_name, ", Balance: $", c.c_acctbal) AS customer_info
    FROM 
        customer c 
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', l.l_quantity, ')'), ', ') AS part_details
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.region_name,
    ARRAY_AGG(p.p_name) AS popular_parts,
    SUM(od.total_revenue) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    ARRAY_AGG(DISTINCT hc.customer_info) AS high_value_customers
FROM 
    RankedParts p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
JOIN 
    OrderDetails od ON od.o_orderkey = ps.ps_partkey
JOIN 
    HighValueCustomers hc ON hc.c_custkey = s.s_suppkey 
WHERE 
    p.rank <= 10 
GROUP BY 
    r.region_name 
ORDER BY 
    total_revenue DESC;
