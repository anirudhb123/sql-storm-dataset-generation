WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_avail_qty
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(s.avg_supplycost) AS total_avg_supply_cost,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_returnflag = 'R') AS total_returns,
    COUNT(DISTINCT cs.c_custkey) AS loyal_customers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    CustomerOrders cs ON n.n_nationkey IN (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.c_custkey)
WHERE 
    s.s_acctbal > 1000.00 OR EXISTS (
        SELECT 1 FROM partsupp ps WHERE ps.ps_supplycost < 5 AND ps.ps_availqty IS NOT NULL
    )
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(s.total_avail_qty) IS NOT NULL AND (COUNT(DISTINCT cs.c_custkey) > 5 OR MAX(s.avg_supplycost) IS NULL)
ORDER BY 
    customer_count DESC, total_avg_supply_cost DESC;
