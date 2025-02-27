
WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rank
    FROM 
        orders
    WHERE 
        o_orderstatus IN ('O', 'F')
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000.00
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost) > 5000.00
)
SELECT 
    o.o_orderkey,
    COUNT(DISTINCT l.l_partkey) AS distinct_parts,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
    COALESCE(ROUND(AVG(spd.ps_supplycost), 2), 0) AS avg_supply_cost,
    r.r_name AS region_name
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPartDetails spd ON l.l_suppkey = spd.s_suppkey AND l.l_partkey = spd.p_partkey
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= '1996-01-01'
GROUP BY 
    o.o_orderkey, r.r_name
HAVING 
    SUM(l.l_quantity) > 10
ORDER BY 
    sales_rank, region_name;
