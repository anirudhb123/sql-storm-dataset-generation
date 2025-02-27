WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        n.n_comment
    FROM 
        nation n 
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    nd.n_name AS nation_name,
    nd.region_name,
    ss.s_name AS supplier_name,
    COALESCE(ss.total_cost, 0) AS supplier_total_cost,
    COALESCE(cs.total_spent, 0) AS customer_total_spent,
    CASE 
        WHEN COALESCE(ss.total_cost, 0) > COALESCE(cs.total_spent, 0) 
        THEN 'Supplier Dominates'
        ELSE 'Customer Dominates'
    END AS dominance_status
FROM 
    NationDetails nd
LEFT JOIN 
    SupplierStats ss ON nd.n_nationkey = ss.s_nationkey
LEFT JOIN 
    CustomerOrders cs ON nd.n_nationkey = cs.c_nationkey
WHERE 
    (ss.total_cost IS NOT NULL OR cs.total_spent IS NOT NULL)
ORDER BY 
    nd.region_name, nation_name, supplier_name;
