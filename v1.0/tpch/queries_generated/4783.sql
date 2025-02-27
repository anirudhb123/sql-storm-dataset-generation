WITH SupplierTotal AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationDetails AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
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
    sd.total_cost,
    sd.part_count,
    nd.n_name,
    nd.region_name,
    cd.c_name,
    cd.order_count,
    cd.total_spent
FROM 
    SupplierTotal sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    NationDetails nd ON ps.ps_partkey IN (SELECT p_partkey FROM part)
LEFT JOIN 
    CustomerOrders cd ON cd.total_spent > 1000
WHERE 
    sd.total_cost IS NOT NULL 
    AND (sd.part_count > 10 OR cd.order_count IS NULL)
ORDER BY 
    sd.total_cost DESC,
    cd.total_spent DESC;
