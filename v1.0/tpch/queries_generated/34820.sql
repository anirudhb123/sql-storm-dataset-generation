WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.n_nationkey,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY total_supply_cost DESC) AS rank_within_nation
    FROM 
        SupplyChain s
)
SELECT 
    c.c_name AS customer_name,
    c.c_acctbal AS customer_balance,
    co.order_count,
    co.total_order_value,
    rs.s_name AS top_supplier_name,
    rs.rank_within_nation
FROM 
    customer c
JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_nationkey = rs.s_nationkey AND rs.rank_within_nation = 1
WHERE 
    co.total_order_value > (
        SELECT 
            AVG(total_order_value)
        FROM 
            CustomerOrders
    )
ORDER BY 
    c.c_acctbal DESC, co.total_order_value DESC;
