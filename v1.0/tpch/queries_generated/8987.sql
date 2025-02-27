WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
)
SELECT 
    rp.p_name, 
    rp.p_brand, 
    rp.p_retailprice, 
    rp.total_avail_qty, 
    rp.supplier_count, 
    h.o_orderkey, 
    h.total_revenue,
    sr.nation_name,
    sr.region_name,
    sr.total_supply_cost
FROM 
    RankedParts rp
JOIN 
    HighValueOrders h ON rp.p_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = h.o_orderkey
    )
JOIN 
    SupplierRegion sr ON rp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey IN (
            SELECT s.s_suppkey 
            FROM supplier s 
            JOIN nation n ON s.s_nationkey = n.n_nationkey 
            JOIN region r ON n.n_regionkey = r.r_regionkey
            WHERE r.r_name = sr.region_name
        )
    )
ORDER BY 
    total_revenue DESC, 
    rp.p_name ASC;
