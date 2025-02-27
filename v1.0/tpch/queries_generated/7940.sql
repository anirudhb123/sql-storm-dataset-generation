WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
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
        SUM(o.o_totalprice) > 100000
),
SupplierCustomerAssociation AS (
    SELECT 
        r.r_name AS region,
        hs.s_name AS top_supplier,
        hc.c_name AS high_value_customer,
        hs.total_supply_value,
        hc.total_spent
    FROM 
        RankedSuppliers hs
    JOIN 
        partsupp ps ON hs.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer hc ON o.o_custkey = hc.c_custkey
    JOIN 
        nation n ON hc.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        hs.supply_rank <= 5 AND
        hc.c_custkey IN (SELECT c_custkey FROM HighValueCustomers)
)
SELECT 
    region,
    top_supplier,
    high_value_customer,
    total_supply_value,
    total_spent
FROM 
    SupplierCustomerAssociation
ORDER BY 
    total_supply_value DESC, total_spent DESC;
