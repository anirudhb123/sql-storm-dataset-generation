WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER(PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost > 100
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal 
    FROM 
        supplier s
    WHERE
        s.s_acctbal IS NOT NULL AND 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_comment IS NOT NULL)
),
CustomerSummary AS (
    SELECT
        c.c_custkey,
        c.c_mktsegment,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_mktsegment
),
NationRegion AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    SUM(ps.total_availqty) AS total_avail,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    c.c_mktsegment,
    AVG(o.o_totalprice) OVER (PARTITION BY c.c_mktsegment) AS avg_market_segment_value,
    COALESCE(nr.n_name, 'Unknown') AS nation_name,
    (SELECT MAX(l.l_discount) FROM lineitem l WHERE l.l_returnflag = 'R') AS max_return_discount,
    CASE 
        WHEN SUM(ps.total_availqty) > 1000 THEN 'High Availability'
        ELSE 'Low Availability'
    END AS availability_status
FROM 
    PartSuppliers ps
JOIN 
    RankedOrders o ON ps.ps_partkey = o.o_orderkey
JOIN 
    FilteredSuppliers s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    CustomerSummary c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    NationRegion nr ON s.s_nationkey = nr.n_nationkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND p.p_size IS NOT NULL 
    AND (p.p_comment IS NULL OR p.p_comment LIKE '%special%')
GROUP BY 
    ps.ps_partkey, p.p_name, c.c_mktsegment, nr.n_name
ORDER BY 
    total_avail DESC, p.p_retailprice ASC
LIMIT 100
OFFSET 50;
