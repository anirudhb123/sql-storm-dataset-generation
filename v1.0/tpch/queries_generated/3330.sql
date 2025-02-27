WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    COALESCE(n.n_name, 'Unknown Region') AS nation_name,
    COALESCE(c.c_name, 'None') AS customer_name,
    c.total_spent AS total_spent,
    n.supplier_count AS total_suppliers,
    n.customer_count AS total_customers,
    s.total_available AS total_parts_available,
    s.part_count AS number_of_parts
FROM 
    NationStats n
FULL OUTER JOIN 
    CustomerOrders c ON n.customer_count IS NOT NULL 
LEFT JOIN 
    SupplierParts s ON c.c_custkey IS NOT NULL OR n.supplier_count IS NOT NULL
WHERE 
    (c.total_spent > 1000 OR n.supplier_count > 5) 
    AND (s.total_available IS NULL OR s.total_available < 100)
ORDER BY 
    n.n_name, c.total_spent DESC;
