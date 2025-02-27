WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')'), ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone, s.s_acctbal
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT o.o_orderstatus, ', ') AS order_statuses
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address
)
SELECT 
    sd.s_name AS supplier_name,
    sd.total_parts AS number_of_parts,
    sd.total_supply_cost AS total_supply_cost,
    cd.c_name AS customer_name,
    cd.total_orders AS number_of_orders,
    cd.total_spent AS customer_total_spent,
    sd.part_names AS supplied_parts,
    cd.order_statuses AS unique_order_statuses
FROM 
    SupplierDetails sd
JOIN 
    CustomerOrderDetails cd ON sd.s_suppkey = ((RANDOM() * (SELECT COUNT(*) FROM supplier))::int + 1)
ORDER BY 
    sd.total_supply_cost DESC, cd.total_spent DESC
LIMIT 10;
