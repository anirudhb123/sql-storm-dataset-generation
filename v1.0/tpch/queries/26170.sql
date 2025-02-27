WITH PartDetails AS (
    SELECT 
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers_list
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    pd.p_name,
    pd.p_mfgr,
    pd.p_brand,
    pd.p_type,
    pd.supplier_count,
    pd.total_available_quantity,
    pd.total_supply_cost,
    pd.suppliers_list,
    co.c_name AS top_customer,
    co.order_count,
    co.total_spent
FROM 
    PartDetails pd
JOIN 
    CustomerOrders co ON pd.total_supply_cost > 100000
ORDER BY 
    pd.total_available_quantity DESC, co.total_spent DESC
LIMIT 10;
