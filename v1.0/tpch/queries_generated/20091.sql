WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_size DESC) AS rn
    FROM 
        part p
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_net,
        o.o_orderdate,
        o.o_orderstatus,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Unknown'
        END AS order_status_desc
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    r.*,
    ps.unique_parts,
    ps.avg_acctbal,
    od.total_price_net,
    od.order_status_desc
FROM 
    RankedParts r
LEFT JOIN 
    SupplierStats ps ON r.rn = 1 AND r.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = ps.s_suppkey)
FULL OUTER JOIN 
    OrderDetails od ON r.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey LIMIT 1)
WHERE 
    (r.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) OR ps.unique_parts IS NULL)
    AND (od.total_price_net > 5000 OR od.total_price_net IS NULL)
ORDER BY 
    r.p_name, od.o_orderdate DESC;
