WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_customer_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    p.p_name,
    co.total_customer_spent,
    so.avg_supply_cost,
    ro.total_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
JOIN 
    lineitem li ON li.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_orderdate = (
            SELECT MAX(o1.o_orderdate)
            FROM orders o1
            WHERE o1.o_custkey = c.c_custkey
        )
    )
JOIN 
    partsupp ps ON ps.ps_partkey = li.l_partkey
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN 
    SupplierStats so ON so.s_suppkey = s.s_suppkey
JOIN 
    (SELECT p.p_partkey, p.p_name 
     FROM part p 
     WHERE p.p_retailprice IS NOT NULL AND p.p_size > 10) p ON p.p_partkey = li.l_partkey
JOIN 
    RankedOrders ro ON ro.o_orderkey = li.l_orderkey
WHERE 
    co.total_customer_spent > (SELECT AVG(total_customer_spent) FROM CustomerOrders)
ORDER BY 
    r.r_name, co.total_customer_spent DESC;
