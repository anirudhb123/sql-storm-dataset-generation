WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice)
            FROM orders o2
            WHERE o2.o_orderstatus = 'O'
        )
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
SeasonedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category,
        AVG(l.l_discount) AS avg_discount
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_size
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    MAX(d.total_supply_cost) AS max_supply_cost,
    SUM(CASE 
            WHEN s.size_category = 'Large' AND d.total_supply_cost > 10000 THEN 1 
            ELSE 0 
        END) AS high_value_parts_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    SupplierDetails d ON d.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey
            FROM part p 
            WHERE p.p_brand = 'Brand#23'
        )
    )
LEFT JOIN 
    SeasonedParts s ON s.p_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l 
        WHERE EXISTS (
            SELECT 1 
            FROM RankedOrders ro 
            WHERE ro.o_orderkey = l.l_orderkey 
            AND ro.rn = 1
        )
    )
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0 
    AND MAX(d.total_supply_cost) IS NOT NULL
ORDER BY 
    customer_count DESC, region_name;
