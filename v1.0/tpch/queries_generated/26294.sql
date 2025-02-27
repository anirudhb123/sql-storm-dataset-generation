WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
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
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierCustomerRelations AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        hs.s_name AS supplier_name,
        hc.c_name AS customer_name,
        hc.total_spent,
        hs.total_supply_value
    FROM 
        RankedSuppliers hs
    JOIN 
        nation ns ON hs.s_nationkey = ns.n_nationkey
    JOIN 
        HighValueCustomers hc ON hc.total_spent > 0
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        hs.rank <= 5
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    customer_name,
    total_spent,
    total_supply_value
FROM 
    SupplierCustomerRelations
ORDER BY 
    region_name, nation_name, total_supply_value DESC, total_spent DESC;
