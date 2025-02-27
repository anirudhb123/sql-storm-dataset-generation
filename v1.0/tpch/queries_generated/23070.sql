WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o1.o_totalprice) FROM orders o1 WHERE o1.o_orderstatus = o.o_orderstatus)
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COALESCE(NULLIF(s.s_comment, ''), 'No comment provided') AS supplier_comment,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_comment
),
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name 
    HAVING 
        COUNT(o.o_orderkey) > 0
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returns,
    SUM(DISTINCT COALESCE(o.o_totalprice, 0)) AS total_order_amount,
    MAX(s.total_supply_cost) OVER () AS max_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey 
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey 
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey AND ro.order_rank = 1
LEFT JOIN 
    CustomerStats cs ON cs.order_count > 5
WHERE 
    r.r_name IS NOT NULL 
    AND n.n_name IS NOT NULL 
    AND ps.ps_availqty >= (SELECT AVG(ps1.ps_availqty) FROM partsupp ps1 WHERE ps1.ps_supplycost < 1000.00)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 1
ORDER BY 
    total_order_amount DESC NULLS LAST;
