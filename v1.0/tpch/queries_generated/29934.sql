WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        s.s_name AS supplier_name,
        s.s_nationkey,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        r.r_name AS region_name,
        COUNT(s.s_suppkey) AS region_supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, r.r_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_size,
    pd.supplier_name,
    od.c_name AS customer_name,
    od.total_orders,
    od.total_spent,
    sr.region_name,
    sr.region_supplier_count
FROM 
    PartSupplierDetails pd
JOIN 
    CustomerOrderSummary od ON pd.s_nationkey = od.c_custkey
JOIN 
    SupplierRegion sr ON pd.supplier_name = sr.s_supplier_name
WHERE 
    pd.ps_availqty > 0 AND
    od.total_spent > 1000
ORDER BY 
    pd.p_name, od.total_spent DESC;
