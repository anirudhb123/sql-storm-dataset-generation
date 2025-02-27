WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
    COALESCE(SUM(os.total_spent), 0) AS total_spent,
    COUNT(DISTINCT CASE WHEN ss.part_count > 5 THEN ss.s_suppkey END) AS high_supply_count
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrderSummary os ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = os.c_custkey)
WHERE 
    n.n_name LIKE 'A%' 
GROUP BY 
    n.n_name
HAVING 
    SUM(ss.total_supply_cost) IS NOT NULL OR SUM(os.total_spent) IS NOT NULL
ORDER BY 
    total_supply_cost DESC, total_spent DESC;
