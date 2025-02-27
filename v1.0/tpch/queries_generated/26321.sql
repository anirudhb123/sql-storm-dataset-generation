WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredOrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderstatus
)
SELECT 
    c.nation_name,
    COUNT(DISTINCT cp.p_partkey) AS part_count,
    SUM(o.line_count) AS total_lines,
    SUM(s.total_supply_cost) AS total_supply_costs,
    MAX(r.p_retailprice) AS highest_price,
    MIN(r.p_retailprice) AS lowest_price 
FROM 
    CustomerNation c
LEFT JOIN 
    RankedParts r ON c.c_custkey = r.p_partkey AND r.rnk <= 10
LEFT JOIN 
    FilteredOrderStats o ON c.c_custkey = o.o_orderkey
LEFT JOIN 
    SupplierInfo s ON c.c_nationkey = s.s_nationkey
GROUP BY 
    c.nation_name
ORDER BY 
    part_count DESC
LIMIT 10;
