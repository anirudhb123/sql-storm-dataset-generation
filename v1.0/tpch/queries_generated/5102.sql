WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighRankingSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost,
        n.n_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank_within_nation <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    hos.n_name AS supplier_nation,
    hos.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.total_order_value,
    co.o_orderdate
FROM 
    HighRankingSuppliers hos
JOIN 
    CustomerOrders co ON hos.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = hos.n_name)
WHERE 
    co.total_order_value > (SELECT AVG(total_order_value) FROM CustomerOrders)
ORDER BY 
    hos.s_name, co.total_order_value DESC;
