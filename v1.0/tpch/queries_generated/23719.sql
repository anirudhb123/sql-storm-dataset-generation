WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionNations AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COALESCE(o.order_count, 0) AS total_orders,
    COALESCE(o.total_spent, 0) AS total_spent,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    CustomerOrders o ON o.c_custkey = s.s_suppkey
WHERE 
    (s.s_acctbal IS NULL OR s.s_acctbal > 100)
    AND (n.n_name LIKE 'A%' OR n.n_name LIKE 'B%')
    AND (CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity < 10 ELSE l.l_quantity >= 10 END)
GROUP BY 
    r.r_name, n.n_name, s.s_name, c.c_name
HAVING 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > 1000
ORDER BY 
    region, revenue_rank;
