WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name,
        SUM(CASE WHEN ps.ps_availqty < 100 THEN ps.ps_supplycost ELSE 0 END) AS low_avail_supplycost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, r.r_name
),
CustomerOrderTotals AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartAggregate AS (
    SELECT 
        p.p_partkey,
        COUNT(ps.ps_supplycost) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p 
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    ci.s_name,
    ci.region_name,
    ci.low_avail_supplycost,
    co.total_spent,
    pa.supplier_count,
    pa.avg_supply_cost
FROM 
    SupplierInfo ci
FULL OUTER JOIN 
    CustomerOrderTotals co ON ci.s_suppkey = co.c_custkey
FULL OUTER JOIN 
    PartAggregate pa ON pa.supplier_count >= 1
WHERE 
    (ci.low_avail_supplycost IS NOT NULL OR co.total_spent IS NOT NULL)
    AND (ci.s_acctbal > 1000 OR co.total_spent < 5000)
ORDER BY 
    ci.low_avail_supplycost DESC NULLS LAST, 
    co.total_spent ASC NULLS FIRST;
