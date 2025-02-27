WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopRegions AS (
    SELECT 
        n.n_regionkey, 
        SUM(o.o_totalprice) AS region_sales
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey
    ORDER BY 
        region_sales DESC
    LIMIT 5
)
SELECT 
    rp.p_name, 
    rp.total_cost, 
    COALESCE(co.total_spent, 0) AS total_spent,
    tr.region_sales
FROM 
    RankedParts rp
LEFT JOIN 
    CustomerOrders co ON rp.p_partkey = co.c_custkey
JOIN 
    TopRegions tr ON tr.n_regionkey = co.c_nationkey
WHERE 
    rp.rank = 1
ORDER BY 
    tr.region_sales DESC, rp.total_cost DESC;
