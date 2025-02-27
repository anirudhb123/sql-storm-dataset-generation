WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps.ps_supplycost * ps.ps_availqty) FROM partsupp ps)
), 
FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT 
    r.r_name AS region,
    p.p_name AS part_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    c.c_name AS customer_name,
    CASE 
        WHEN p.total_supply_cost IS NOT NULL THEN 'High Supply Cost'
        ELSE 'Normal Supply Cost'
    END AS supply_cost_status,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    lineitem li
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    region r ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = c.c_nationkey)
LEFT JOIN 
    HighValueParts p ON li.l_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = li.l_suppkey AND s.rnk <= 3
WHERE 
    li.l_shipdate > o.o_orderdate AND li.l_discount BETWEEN 0.05 AND 0.15
GROUP BY 
    r.region, p.p_name, c.c_name
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > (SELECT AVG(l_extendedprice) FROM lineitem)
ORDER BY 
    total_revenue DESC, region, part_name;
