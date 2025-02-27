WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey
),
HighValueSuppliers AS (
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
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
),
JoinWithNULL AS (
    SELECT 
        r.r_name,
        n.n_name,
        COALESCE(SUM(lp.l_extendedprice), 0) AS total_price
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem lp ON ps.ps_partkey = lp.l_partkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    (SELECT COUNT(*) FROM HighValueSuppliers) AS high_value_supplier_count,
    rws.r_name,
    rws.total_price,
    CASE 
        WHEN rws.total_price > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    JoinWithNULL rws
JOIN 
    RankedOrders ro ON rws.r_name IS NOT NULL AND ro.revenue_rank = 1
ORDER BY 
    rws.total_price DESC
LIMIT 10;