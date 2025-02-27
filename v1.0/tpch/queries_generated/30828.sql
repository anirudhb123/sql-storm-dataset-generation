WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSpenders AS (
    SELECT 
        c.c_nationkey,
        SUM(co.total_spent) AS nation_spending
    FROM 
        nation c
    JOIN 
        CustomerOrders co ON c.n_nationkey = co.c_custkey
    GROUP BY 
        c.c_nationkey
),
PartSupply AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_supply
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
HighDemandParts AS (
    SELECT 
        part.p_partkey,
        part.p_name,
        COUNT(line.l_orderkey) AS line_count
    FROM 
        part part
    JOIN 
        lineitem line ON part.p_partkey = line.l_partkey
    GROUP BY 
        part.p_partkey, part.p_name
    HAVING 
        COUNT(line.l_orderkey) > 10
)
SELECT 
    n.n_name AS nation,
    SUM(ts.nation_spending) AS total_spending,
    COALESCE(SUM(ps.total_supply), 0) AS total_part_supply,
    hdp.p_name AS high_demand_part,
    hdp.line_count
FROM 
    TopSpenders ts
JOIN 
    nation n ON ts.c_nationkey = n.n_nationkey
LEFT JOIN 
    PartSupply ps ON n.n_nationkey = ps.p_partkey
LEFT JOIN 
    HighDemandParts hdp ON ps.p_partkey = hdp.p_partkey
WHERE 
    ts.nation_spending > 10000
GROUP BY 
    n.n_name, hdp.p_name, hdp.line_count
ORDER BY 
    total_spending DESC, hdp.line_count DESC;
