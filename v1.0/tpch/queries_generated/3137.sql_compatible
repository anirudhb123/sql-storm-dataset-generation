
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate <= DATE '1996-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey = s.s_nationkey
        )
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_returnflag) AS return_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    s.s_name AS supplier_name,
    s.nation_name,
    h.p_name AS part_name,
    h.total_value AS part_total_value,
    la.net_revenue,
    la.return_count
FROM 
    RankedOrders o
LEFT JOIN 
    LineItemAnalysis la ON o.o_orderkey = la.l_orderkey
JOIN 
    SupplierDetails s ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey FROM HighValueParts p WHERE p.p_name LIKE '%widget%'
        ) 
        ORDER BY ps.ps_supplycost DESC 
        LIMIT 1
    )
JOIN 
    HighValueParts h ON h.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey = s.s_suppkey
    )
WHERE 
    o.order_rank <= 10 AND 
    o.o_orderstatus IN ('O', 'F')
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice DESC;
