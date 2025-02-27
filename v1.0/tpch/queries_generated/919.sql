WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rank_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    MAX(co.o_totalprice) AS max_order_value,
    COUNT(DISTINCT ss.s_suppkey) AS active_suppliers
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey IN (
        SELECT o.o_orderkey FROM orders o WHERE o.o_totalprice > 5000
    )
LEFT JOIN 
    RankedSuppliers ss ON p.p_partkey = ss.ps_partkey AND ss.rank_cost = 1
WHERE 
    p.p_size > 10 AND 
    (n.n_name IS NOT NULL OR s.s_acctbal > 1000) 
GROUP BY 
    p.p_partkey, p.p_name, n.n_name, c.c_name
HAVING 
    total_quantity > 100
ORDER BY 
    avg_price_after_discount DESC;
