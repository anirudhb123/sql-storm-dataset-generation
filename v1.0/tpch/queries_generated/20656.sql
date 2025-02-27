WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Pending'
        END AS order_status
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), 
RegionNations AS (
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
    p.p_partkey,
    p.p_name,
    COALESCE(ss.part_count, 0) AS supplier_count,
    COALESCE(ss.total_supplycost, 0) AS total_supplycost,
    hvo.net_value,
    rn.rn
FROM 
    RankedParts p
LEFT JOIN 
    SupplierStats ss ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE ss.part_count >= 5))
LEFT JOIN 
    HighValueOrders hvo ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F'))
LEFT JOIN 
    RegionNations n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE EXISTS (SELECT 1 FROM orders o WHERE o.o_custkey = c.c_custkey AND o.o_orderdate = p.p_retailprice::date))
WHERE 
    p.p_size BETWEEN 20 AND 30
ORDER BY 
    p.p_retailprice DESC, hvo.net_value ASC
LIMIT 100;
