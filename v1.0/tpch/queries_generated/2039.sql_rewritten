WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierAggregation AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_cost_total
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        pa.supply_cost_total,
        ROW_NUMBER() OVER (ORDER BY pa.supply_cost_total DESC) AS rank
    FROM 
        part p
    LEFT JOIN 
        SupplierAggregation pa ON p.p_partkey = pa.ps_partkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(l.l_extendedprice) AS average_extended_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS top_parts,
    SUM(coalesce(l.l_discount * l.l_extendedprice, 0)) AS discount_total
FROM 
    TopParts p 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.rank <= 10 AND 
    o.o_orderstatus = 'P' AND 
    (c.c_acctbal IS NOT NULL OR c.c_mktsegment IN ('AUTO', 'FURN', 'COPR'))
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    customer_count DESC, average_extended_price DESC;