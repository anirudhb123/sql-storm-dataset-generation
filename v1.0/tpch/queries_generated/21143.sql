WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
),
SuppliersWithHighCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) as total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        AVG(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
AdditionalComments AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers,
        STRING_AGG(DISTINCT s.s_comment) AS supplier_comments
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(t.total_cost, 0) AS average_supply_cost,
    c.c_name,
    c.order_count,
    c.total_spent,
    ac.distinct_suppliers,
    ac.supplier_comments
FROM 
    part p
LEFT JOIN 
    SuppliersWithHighCosts t ON p.p_partkey = t.ps_partkey
LEFT JOIN 
    CustomerOrderStats c ON c.c_custkey IN (SELECT o.o_custkey FROM RankedOrders r WHERE r.o_orderkey = o.o_orderkey) 
LEFT JOIN 
    AdditionalComments ac ON EXISTS (SELECT 1 FROM supplier WHERE s_nationkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = 'ASIA'))
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) AND 
    (c.order_count > 10 OR ac.distinct_suppliers IS NOT NULL)
ORDER BY 
    p.p_partkey, c.total_spent DESC
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
