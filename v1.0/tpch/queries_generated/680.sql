WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS region_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
)
SELECT 
    pr.p_partkey,
    pr.p_name,
    COALESCE(rng.o_orderdate, 'No Orders') AS last_order_date, 
    cs.region_name AS customer_region,
    cs.total_spent,
    ss.total_supplycost AS total_cost,
    ss.total_suppliers
FROM 
    part pr
LEFT JOIN 
    RankedOrders rng ON pr.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = (SELECT s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') LIMIT 1) LIMIT 1)
LEFT JOIN 
    SupplierStats ss ON pr.p_partkey = ss.ps_partkey
LEFT JOIN 
    CustomerRegion cs ON cs.total_spent > 1000
WHERE 
    pr.p_size BETWEEN 1 AND 10
ORDER BY 
    COALESCE(rng.o_orderdate, 'No Orders'), pr.p_name;
