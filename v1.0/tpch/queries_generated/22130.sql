WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
NationCustomerOrders AS (
    SELECT 
        n.n_name,
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus <> 'F'
    GROUP BY 
        n.n_name, c.c_custkey
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) OVER (PARTITION BY ps.ps_partkey) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    nco.n_name,
    COALESCE(SUM(nco.total_spent), 0) AS total_customer_spent,
    COUNT(DISTINCT rs.s_suppkey) AS total_suppliers,
    COALESCE(SUM(ps.total_available_qty), 0) AS grand_total_available_qty,
    COALESCE(SUM(ps.total_supply_cost), 0) AS grand_total_supply_cost
FROM 
    NationCustomerOrders nco
LEFT JOIN 
    RankedSuppliers rs ON nco.n_name = SUBSTRING(rs.s_name FROM 1 FOR 25)
LEFT JOIN 
    PartSupplierDetails ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_container LIKE 'SMALL%' OR p.p_size BETWEEN 1 AND 10)
WHERE 
    nco.total_orders IS NULL OR nco.num_orders > 5
GROUP BY 
    nco.n_name
HAVING 
    COUNT(DISTINCT rs.s_suppkey) > 2
ORDER BY 
    total_customer_spent DESC NULLS LAST;
