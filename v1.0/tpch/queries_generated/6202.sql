WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 5000
),
FinalJoin AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        o.o_orderkey,
        o.o_orderdate,
        h.total_supply_value
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.o_orderkey IN (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_custkey = c.c_custkey)
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        HighValueSuppliers h ON h.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey))
)
SELECT 
    region_name,
    nation_name,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    AVG(total_supply_value) AS average_supply_value
FROM 
    FinalJoin
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, nation_name;
