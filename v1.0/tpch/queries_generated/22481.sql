WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        part p 
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey 
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    MAX(pi.total_revenue) AS max_revenue,
    COALESCE(SUM(ci.total_spent), 0) AS total_spent_by_customers,
    (SELECT COUNT(*) 
     FROM lineitem l 
     WHERE l.l_shipdate > CURRENT_DATE - INTERVAL '30 days') AS recent_shipments,
    (SELECT COUNT(*) 
     FROM RankedOrders ro 
     WHERE ro.order_rank <= 5 AND ro.o_orderdate < CURRENT_DATE - INTERVAL '90 days'
     AND ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')) AS historic_count
FROM 
    region r 
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierInfo si ON si.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN 
                                          (SELECT p.p_partkey FROM part p WHERE p.p_size >= 10))
LEFT JOIN 
    PartDetails pi ON pi.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_returnflag = 'R')
LEFT JOIN 
    CustomerOrders ci ON ci.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = 1)
GROUP BY 
    r.r_name
HAVING 
    MAX(pi.total_revenue) IS NOT NULL OR COALESCE(SUM(ci.total_spent), 0) > 1000
ORDER BY 
    nation_count DESC, total_spent_by_customers ASC;
