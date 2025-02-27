WITH part_supplier_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
nation_region_info AS (
    SELECT 
        n.n_nationkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    psi.p_partkey,
    psi.p_name,
    psi.supplier_name,
    psi.supplier_address,
    nri.nation_name,
    nri.region_name,
    co.customer_name,
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice,
    CONCAT(psi.p_brand, ' - ', psi.p_name) AS detailed_part_description,
    SUBSTRING(psi.p_type, 1, 10) AS short_part_type,
    ROUND(psi.ps_supplycost * psi.ps_availqty, 2) AS total_cost,
    CASE 
        WHEN co.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS order_value_classification
FROM 
    part_supplier_info psi
JOIN 
    nation_region_info nri ON psi.p_partkey % 5 = nri.n_nationkey  -- Mocking a relationship for demonstration
JOIN 
    customer_orders co ON psi.p_partkey % 10 = co.c_custkey  -- Mocking a relationship for demonstration
WHERE 
    psi.ps_availqty > 50
ORDER BY 
    psi.p_name, co.o_orderdate DESC;
