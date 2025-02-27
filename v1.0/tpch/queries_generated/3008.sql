WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) AS total_revenue,
    AVG(co.o_totalprice) AS average_order_value,
    COUNT(DISTINCT cs.c_custkey) AS unique_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem lo ON ps.ps_partkey = lo.l_partkey
JOIN 
    CustomerOrders co ON co.o_orderkey = lo.l_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = s.s_suppkey AND rs.supply_rank = 1
WHERE 
    r.r_name IS NOT NULL 
    AND co.order_rank <= 10
    AND lo.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
