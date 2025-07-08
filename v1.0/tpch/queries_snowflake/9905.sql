WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), TopNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(o.o_totalprice) AS total_orders
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON s.s_suppkey = c.c_custkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
    ORDER BY 
        total_orders DESC
    LIMIT 5
)
SELECT 
    rp.p_name,
    tn.n_name,
    rp.total_supply_cost,
    tn.total_orders
FROM 
    RankedParts rp
JOIN 
    TopNations tn ON tn.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey LIMIT 1))
WHERE 
    rp.rank = 1
ORDER BY 
    rp.total_supply_cost DESC, 
    tn.total_orders DESC;
