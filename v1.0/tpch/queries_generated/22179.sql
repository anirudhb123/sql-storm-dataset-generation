WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey
    FROM 
        SupplierSummary s
    WHERE 
        total_cost > (SELECT AVG(total_cost) FROM SupplierSummary)
),
NationRanked AS (
    SELECT 
        n.n_name,
        RANK() OVER (ORDER BY COUNT(s.s_suppkey) DESC) AS supplier_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    SUM(l.l_quantity * (1 - l.l_discount)) AS total_quantity_sold,
    AVG(l.l_extendedprice) AS avg_price_per_line,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    DENSE_RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice) DESC) AS popularity_rank,
    STRING_AGG(DISTINCT CASE WHEN n.supplier_rank <= 2 THEN n.n_name END, ', ') AS top_nations
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    NationRanked n ON s.s_nationkey = n.n_nationkey
WHERE 
    (l.l_returnflag = 'N' OR l.l_returnflag IS NULL) AND 
    (l.l_shipmode = 'AIR' OR l.l_shipmode = 'TRUCK') AND 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00) AND 
    s.s_suppkey IN (SELECT s_suppkey FROM HighValueSuppliers)
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
HAVING 
    SUM(l.l_quantity * (1 - l.l_discount)) > 50 AND 
    AVG(l.l_extendedprice) < (SELECT AVG(l_extendedprice) FROM lineitem)
ORDER BY 
    popularity_rank, total_quantity_sold DESC;
