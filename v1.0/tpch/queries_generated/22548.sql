WITH RECURSIVE OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_num
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND l.l_returnflag = 'N'
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availqty,
        MAX(p.p_retailprice) AS max_retailprice
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 100 OR MAX(p.p_retailprice) > 500
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(s.s_nationkey) OVER (PARTITION BY s.s_nationkey) AS supplier_count
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
RankedOrders AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_price,
        SUM(od.l_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY od.o_orderkey ORDER BY SUM(od.l_extendedprice * (1 - od.l_discount)) DESC) AS price_rank
    FROM 
        OrderDetails od
    GROUP BY 
        od.o_orderkey, od.o_orderdate
)
SELECT 
    r.r_name,
    COUNT(DISTINCT COALESCE(o.o_orderkey, 0)) AS orders_count,
    SUM(rpo.total_price) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedOrders rpo ON rpo.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_mktsegment = 'BUILDING'))
LEFT JOIN 
    FilteredParts fp ON fp.p_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= DATEADD(month, -12, CURRENT_DATE())))
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 
    AND AVG(s.s_acctbal) > 1000
ORDER BY 
    total_revenue DESC NULLS LAST;
