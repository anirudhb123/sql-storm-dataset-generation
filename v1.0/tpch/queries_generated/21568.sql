WITH RecursiveSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NTILE(4) OVER (ORDER BY s.s_acctbal DESC), 0) AS acctbal_quartile
    FROM 
        supplier s
),
FilteredPart AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 10)
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    nt.n_name AS nation_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returned_items,
    AVG(ps.ps_supplycost * l.l_quantity) AS avg_supply_cost,
    MAX(ps.ps_availqty) AS max_available_quantity,
    STRING_AGG(DISTINCT p.p_name, ', ') AS popular_parts,
    COUNT(DISTINCT cs.c_custkey) FILTER (WHERE cs.total_orders > 5) AS frequent_customers
FROM 
    region r
JOIN 
    nation nt ON nt.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = nt.n_nationkey
JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    FilteredPart p ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    CustomerOrderStats cs ON cs.total_spent > 1000000
WHERE 
    l.l_shipdate >= DATEADD(MONTH, -1, CURRENT_DATE)
GROUP BY 
    r.r_name, nt.n_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY 
    returned_items DESC, avg_supply_cost ASC;
