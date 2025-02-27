WITH PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierNationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_account_balance,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_name AS part_name,
    ps.total_supply_cost,
    ps.supplier_count,
    co.total_orders,
    co.total_spent,
    sn.total_account_balance,
    sn.total_suppliers
FROM 
    PartSupplierStats ps
LEFT JOIN 
    CustomerOrderStats co ON ps.p_partkey = co.c_custkey
FULL OUTER JOIN 
    SupplierNationStats sn ON ps.supplier_count = sn.total_suppliers
WHERE 
    (ps.total_supply_cost > 10000 OR co.total_spent IS NOT NULL)
ORDER BY 
    ps.total_supply_cost DESC, co.total_spent ASC
LIMIT 50;
