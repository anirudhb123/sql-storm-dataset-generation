WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps 
    GROUP BY 
        ps.ps_partkey 
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    r.nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.revenue) AS total_revenue,
    COUNT(DISTINCT ps.ps_partkey) AS high_value_parts_count,
    MAX(s.s_acctbal) AS max_supplier_acctbal
FROM 
    RankedSuppliers s 
JOIN 
    RecentOrders o ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p))
JOIN 
    HighValueParts ps ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
JOIN 
    nation r ON s.nation_name = r.n_name
WHERE 
    s.rank <= 5
GROUP BY 
    r.nation_name
ORDER BY 
    total_revenue DESC, total_orders DESC;
