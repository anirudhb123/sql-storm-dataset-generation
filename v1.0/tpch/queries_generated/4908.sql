WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(ho.o_orderkey) AS high_value_order_count,
        SUM(ho.o_totalprice) AS total_high_value_spent
    FROM 
        customer c
    LEFT JOIN 
        HighValueOrders ho ON c.c_custkey = ho.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartPopularity AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(l.l_orderkey) AS order_count,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(cs.high_value_order_count, 0) AS high_value_order_count,
    COALESCE(cs.total_high_value_spent, 0) AS total_high_value_spent,
    pp.p_partkey,
    pp.p_name,
    pp.order_count,
    pp.total_revenue,
    ss.total_avail_qty,
    ss.avg_supply_cost
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    PartPopularity pp ON pp.total_revenue > 10000
LEFT JOIN 
    SupplierStats ss ON pp.p_partkey = ss.s_suppkey
WHERE 
    (cs.high_value_order_count > 1 OR cs.total_high_value_spent > 1000)
ORDER BY 
    cs.total_high_value_spent DESC, pp.total_revenue DESC;
