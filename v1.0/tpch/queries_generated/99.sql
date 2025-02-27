WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    r.r_name,
    n.n_name,
    COALESCE(c.total_spent, 0) AS total_spent_by_customer,
    COALESCE(ss.total_cost, 0) AS total_supplied_cost,
    COUNT(DISTINCT lo.l_orderkey) AS total_orders,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
FROM 
    part p
LEFT JOIN 
    lineitem lo ON p.p_partkey = lo.l_partkey
LEFT JOIN 
    orders o ON lo.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    supplier s ON lo.l_suppkey = s.s_suppkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
WHERE 
    (lo.l_returnflag = 'R' OR lo.l_linestatus = 'O') AND
    p.p_retailprice > 100.00
GROUP BY 
    p.p_name, r.r_name, n.n_name, c.total_spent
HAVING 
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 1000.00 OR COUNT(DISTINCT lo.l_orderkey) > 10
ORDER BY 
    total_revenue DESC, total_spent_by_customer DESC;
