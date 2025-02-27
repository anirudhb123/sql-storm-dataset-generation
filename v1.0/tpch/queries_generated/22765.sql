WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS high_value_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_discount > 0.1
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(NULLIF(p.p_comment, ''), 'No Comment') AS p_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        pd.p_name,
        pd.p_retailprice
    FROM 
        partsupp ps
    JOIN 
        PartDetails pd ON ps.ps_partkey = pd.p_partkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT spd.ps_partkey) AS total_parts,
    SUM(spd.ps_supplycost) AS total_supply_cost,
    AVG(spd.ps_availqty) AS avg_avail_qty,
    STRING_AGG(DISTINCT spd.p_name, ', ') AS supplier_parts,
    (SELECT COUNT(*) FROM HighValueOrders hvo WHERE hvo.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31') AS high_value_orders_in_year
FROM 
    RankedSuppliers r
LEFT JOIN 
    SupplierPartDetails spd ON r.s_suppkey = spd.ps_suppkey
WHERE 
    r.rnk <= 5
GROUP BY 
    r.r_regionkey, r.r_name
ORDER BY 
    total_supply_cost DESC;
