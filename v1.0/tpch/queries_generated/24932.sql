WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
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
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS total_returns,
    MAX(hvc.total_spent) AS max_customer_spent,
    COALESCE(MIN(pd.avg_supply_cost), 'No Supplier') AS min_avg_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
WHERE 
    r.r_name LIKE '%East%' 
    AND n.n_name IN (SELECT n_name FROM nation WHERE n_comment IS NOT NULL)
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 0
ORDER BY 
    region_name, nation_name DESC;
