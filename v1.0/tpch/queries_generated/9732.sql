WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    cs.c_name,
    cs.total_spent,
    ss.part_count,
    ss.total_cost
FROM 
    NationStats ns
JOIN 
    SupplierStats ss ON ss.s_suppkey IN (SELECT s.s_suppkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE n.n_nationkey = ns.n_nationkey)
JOIN 
    CustomerOrders cs ON cs.c_custkey IN (SELECT o.o_custkey FROM orders o JOIN customer c ON o.o_custkey = c.c_custkey WHERE o.o_totalprice > 1000)
ORDER BY 
    ns.n_name, cs.total_spent DESC;
