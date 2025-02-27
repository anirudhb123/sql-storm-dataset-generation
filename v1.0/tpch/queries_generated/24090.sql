WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TotalOrderCount AS (
    SELECT 
        o.o_custkey,
        COUNT(*) AS total_orders
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(total_supply_value) FROM (SELECT SUM(ps_supplycost * ps_availqty) AS total_supply_value FROM partsupp ps GROUP BY ps.ps_partkey) AS avg_supply)
),
OrderValueSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.region_name,
    hs.s_name AS supplier_name,
    p.p_name AS part_name,
    MAX(ovs.order_value) AS max_order_value,
    COUNT(DISTINCT t.total_orders) AS unique_customers,
    COUNT(*) OVER () AS total_records
FROM 
    RankedSuppliers hs
LEFT JOIN 
    HighValueParts p ON hs.rank <= 5 
LEFT JOIN 
    TotalOrderCount t ON hs.s_suppkey = t.o_custkey
LEFT JOIN 
    OrderValueSummary ovs ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = t.o_custkey))
WHERE 
    hs.rank IS NOT NULL
GROUP BY 
    r.region_name, hs.s_name, p.p_name
HAVING 
    MAX(ovs.order_value) IS NOT NULL
ORDER BY 
    r.region_name, unique_customers DESC, max_order_value DESC
LIMIT 10;
