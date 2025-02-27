WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ARRAY_AGG(s.s_name) AS suppliers_list,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY COUNT(DISTINCT ps.ps_suppkey) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
)

SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.supplier_count,
    rp.suppliers_list,
    co.c_name,
    co.order_count,
    co.total_spent,
    ts.total_suppliers,
    ts.supplier_names
FROM 
    RankedParts rp
JOIN 
    CustomerOrders co ON co.order_count > 0
JOIN 
    TopSuppliers ts ON ts.total_suppliers > 5
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.supplier_count DESC, co.total_spent DESC;
