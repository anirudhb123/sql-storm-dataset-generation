WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_per_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT ts.s_suppkey) AS supplier_count, 
        SUM(ts.total_supply_cost) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        RankedSuppliers ts ON n.n_nationkey = ts.s_nationkey
    WHERE 
        ts.rank_per_nation <= 3
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name, 
    n.supplier_count, 
    n.total_supply_cost,
    AVG(o.o_totalprice) AS avg_order_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    TopNations n
JOIN 
    orders o ON n.n_nationkey = (SELECT n_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
GROUP BY 
    n.n_name, n.supplier_count, n.total_supply_cost
ORDER BY 
    n.total_supply_cost DESC;
