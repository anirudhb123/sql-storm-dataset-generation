WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        part AS p
    JOIN 
        partsupp AS ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
), HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer AS c
    JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue,
        COUNT(DISTINCT l.l_partkey) AS total_items
    FROM 
        orders AS o
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COUNT(DISTINCT h.c_custkey) AS high_value_customer_count,
    AVG(p.total_available_quantity) AS avg_part_availability,
    SUM(d.order_revenue) AS total_revenue_generated
FROM 
    region AS r
JOIN 
    nation AS n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier AS s ON n.n_nationkey = s.s_nationkey
JOIN 
    HighValueCustomers AS h ON s.s_nationkey = h.c_nationkey
JOIN 
    RankedParts AS p ON p.p_brand = s.s_name
JOIN 
    OrderDetails AS d ON d.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = h.c_custkey)
GROUP BY 
    r.n_name
ORDER BY 
    total_revenue_generated DESC;
