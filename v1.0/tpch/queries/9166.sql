
WITH RECURSIVE nation_supply AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost AS min_supply_cost,
        (SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) 
         FROM lineitem l 
         WHERE l.l_shipdate < '1997-10-01' AND l.l_partkey = p.p_partkey) AS total_sales
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    ns.n_name,
    pd.p_name,
    pd.total_sales,
    ns.total_supply_cost,
    pd.min_supply_cost
FROM 
    nation_supply ns
JOIN 
    part_details pd ON ns.n_nationkey = (SELECT s.s_nationkey FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey WHERE ps.ps_partkey = pd.p_partkey FETCH FIRST 1 ROW ONLY)
WHERE 
    pd.total_sales IS NOT NULL
ORDER BY 
    ns.total_supply_cost DESC, 
    pd.total_sales DESC
LIMIT 10;
