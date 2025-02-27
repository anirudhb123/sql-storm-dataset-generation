
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn_status,
        DENSE_RANK() OVER (ORDER BY o.o_totalprice) AS dr_totalprice
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        STRING_AGG(s.s_comment, ', ') AS comments
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) IS NOT NULL
),
LargestPart AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    ORDER BY 
        supplier_count DESC
    LIMIT 1
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    d.s_name AS supplier_name,
    p.p_name AS part_name,
    d.total_supplycost,
    d.comments,
    CASE 
        WHEN r.o_orderstatus = 'O' THEN 'Active' 
        WHEN r.o_orderstatus = 'F' THEN 'Finalized' 
        ELSE 'Unknown' 
    END AS order_status_description
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierDetails d ON r.o_orderkey = d.s_suppkey
INNER JOIN 
    LargestPart p ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = d.s_suppkey ORDER BY ps.ps_availqty DESC LIMIT 1)
WHERE 
    r.rn_status <= 10 
    AND (d.total_supplycost IS NULL OR d.total_supplycost >= 1000)
    AND r.o_orderkey IS NOT NULL 
    AND COALESCE(r.o_orderdate, DATE '1900-01-01') > DATE '2000-01-01'
ORDER BY 
    r.o_totalprice DESC, 
    d.comments
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
