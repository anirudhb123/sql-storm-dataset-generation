WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(ss.total_parts, 0) AS total_parts,
    COALESCE(cs.total_spent, 0) AS total_spent,
    SUM(CASE 
        WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END) AS total_discounted_sales,
    RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice) DESC) AS sales_rank
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrderSummary cs ON cs.total_orders > 5
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_nationkey, n.n_name, ss.total_parts, cs.total_spent
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    sales_rank, total_spent DESC;
