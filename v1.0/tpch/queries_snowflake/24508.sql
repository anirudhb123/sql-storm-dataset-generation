
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR, o.o_orderdate) ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATE '1997-01-01'
),
AggregatedSuppliers AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS brand_count
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 100.00)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    AVG(GREATEST(NULLIF(a.total_supply_value, 0), 1)) AS avg_supply_value,
    SUM(CASE WHEN h.total_line_value IS NOT NULL THEN 1 ELSE 0 END) AS high_value_order_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    AggregatedSuppliers a ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = a.s_suppkey LIMIT 1)
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey IN (SELECT r.o_orderkey FROM RankedOrders r WHERE r.order_rank <= 10)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 2 OR 
    (AVG(a.total_supply_value) IS NOT NULL AND AVG(a.total_supply_value) < 5000)
ORDER BY 
    r.r_name DESC
LIMIT 5;
