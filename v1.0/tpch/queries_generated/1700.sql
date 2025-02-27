WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2022-01-01'
),
AggregatedSupplier AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        total_spent > 10000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(a.avg_supply_cost) AS avg_supply_cost_per_supplier
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM HighValueCustomers c))
LEFT JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN 
    AggregatedSupplier a ON s.s_suppkey = a.s_suppkey
WHERE 
    s.s_acctbal IS NOT NULL 
    AND l.l_shipdate IS NOT NULL 
    AND r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
