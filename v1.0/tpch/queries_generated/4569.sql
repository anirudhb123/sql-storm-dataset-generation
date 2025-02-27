WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
LineitemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    COALESCE(SUM(l.total_revenue), 0) AS total_revenue,
    COALESCE(MAX(rs.total_supply_cost), 0) AS max_supplier_cost,
    rs.rn,
    ns.n_name
FROM 
    CustomerOrders co
LEFT JOIN 
    LineitemDetails l ON co.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = co.o_orderkey))
JOIN 
    nation ns ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey)
WHERE 
    (rs.rn <= 3 OR rs.rn IS NULL)
GROUP BY 
    co.c_name, rs.rn, ns.n_name
ORDER BY 
    total_orders DESC, total_revenue DESC;
