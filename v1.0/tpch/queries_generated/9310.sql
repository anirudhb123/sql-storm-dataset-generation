WITH NationSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
), 
PartSuppliers AS (
    SELECT 
        p.p_name AS part_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name
), 
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_name
)
SELECT 
    ns.nation_name,
    ns.supplier_count,
    ns.total_account_balance,
    ps.part_name,
    ps.total_available_quantity,
    ps.average_supply_cost,
    co.customer_name,
    co.orders_count,
    co.total_spent
FROM 
    NationSuppliers ns
JOIN 
    PartSuppliers ps ON ns.supplier_count > 5
JOIN 
    CustomerOrders co ON co.orders_count > 10
ORDER BY 
    ns.total_account_balance DESC, ps.average_supply_cost ASC;
