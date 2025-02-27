WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.nationkey,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT n.n_nationkey) > 1
)
SELECT 
    c.c_name,
    SUM(co.total_lineitem_price) AS customer_total,
    COALESCE(CAST(NULLIF(MAX(rs.rank), 0) AS VARCHAR), 'No Suppliers') AS supplier_rank,
    tr.r_name AS region_name
FROM 
    CustomerOrders co
JOIN 
    customer c ON co.c_nationkey = c.c_nationkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_nationkey = rs.nationkey
LEFT JOIN 
    TopRegions tr ON c.c_nationkey = tr.nation_count
GROUP BY 
    c.c_name, tr.r_name
ORDER BY 
    customer_total DESC;
