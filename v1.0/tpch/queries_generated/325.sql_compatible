
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 MONTH'
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    COALESCE(SUM(CASE WHEN cs.order_rank = 1 THEN od.total_order_value END), 0) AS highest_order_value,
    SUM(rs.total_supply_cost) AS total_supplier_cost,
    COUNT(DISTINCT rs.s_suppkey) AS num_suppliers
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey = c.c_custkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = cs.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = (
                SELECT 
                    l.l_partkey 
                FROM 
                    lineitem l 
                WHERE 
                    l.l_orderkey = od.o_orderkey 
                LIMIT 1
            )
        ORDER BY 
            ps.ps_supplycost * ps.ps_availqty DESC 
        LIMIT 1
    )
GROUP BY 
    n.n_name
ORDER BY 
    num_customers DESC, highest_order_value DESC;
