WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), 

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(AVG(ps.ps_supplycost), 0), MAX(ps.ps_supplycost)) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 

HighValueCustomers AS (
    SELECT 
        DISTINCT c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT p.p_partkey) AS total_parts,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT CONCAT(c.c_name, ' (', h.total_spent, ')') ORDER BY h.total_spent DESC) AS spending_customers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    HighValueCustomers h ON s.s_suppkey IN (SELECT ps2.ps_suppkey FROM partsupp ps2 WHERE ps2.ps_partkey = p.p_partkey)
WHERE 
    p.p_size IS NOT NULL OR l.l_returnflag = 'R'
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5 AND 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC NULLS LAST;
