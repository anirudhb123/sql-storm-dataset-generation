WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totprice,
        o.o_orderdate,
        COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_totprice, o.o_orderdate
    HAVING 
        o.o_totprice > 5000
),
CombinedData AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name, p.p_brand
),
RegionStatistics AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(c.c_acctbal) AS total_acctbal
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT h.o_orderkey) AS high_value_orders,
    SUM(COALESCE(cd.total_availqty, 0)) AS total_avail_qty,
    AVG(rd.total_acctbal) AS avg_acctbal,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    HighValueOrders h
JOIN 
    RankedSuppliers s ON s.rn <= 3
LEFT JOIN 
    CombinedData cd ON cd.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps)
JOIN 
    RegionStatistics r ON r.nation_count > 2
GROUP BY 
    r.r_name;
