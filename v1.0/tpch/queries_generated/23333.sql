WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name
    FROM 
        region r
    WHERE 
        EXISTS (
            SELECT 1
            FROM nation n
            WHERE n.n_regionkey = r.r_regionkey AND n.n_comment IS NOT NULL
        )
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_name, 
    r.r_name, 
    COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied, 
    SUM(COALESCE(ps.ps_supplycost * ps.ps_availqty, 0)) AS total_parts_cost,
    MAX(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE NULL END) AS max_fully_delivered_order,
    AVG(NULLIF(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice END, 0)) AS avg_returned_price,
    SUM(CASE WHEN l.l_shipdate < o.o_orderdate THEN 1 ELSE 0 END) AS early_shipments
FROM 
    customer c
JOIN 
    nations n ON c.c_nationkey = n.n_nationkey
JOIN 
    FilteredRegions r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
WHERE 
    c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer) 
    OR EXISTS (
        SELECT 1 
        FROM RankedSuppliers rs 
        WHERE rs.rank_within_nation <= 10 AND rs.s_suppkey = ps.ps_suppkey
    )
GROUP BY 
    c.c_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > COALESCE(NULLIF(SUM(l.l_tax), 0), 1)
ORDER BY 
    total_parts_cost DESC, c.c_name;
