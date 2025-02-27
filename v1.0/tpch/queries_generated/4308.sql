WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
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
    HAVING 
        SUM(o.o_totalprice) > 1000
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    ps.p_name,
    ps.total_supply_cost,
    ps.total_suppliers,
    rs.s_name,
    rs.s_acctbal
FROM 
    CustomerOrders co
JOIN 
    PartSupplierDetails ps ON co.total_spent > ps.total_supply_cost
LEFT JOIN 
    RankedSuppliers rs ON rs.supp_rank = 1 AND rs.s_suppkey IN (
        SELECT DISTINCT ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (SELECT p_partkey FROM part WHERE p_size > 50)
    )
WHERE 
    co.order_count > (
        SELECT AVG(order_count) 
        FROM CustomerOrders
    )
ORDER BY 
    co.total_spent DESC, 
    ps.total_supply_cost ASC
