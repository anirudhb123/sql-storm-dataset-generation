WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_comment, ''), 'No Comment') AS comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name
    FROM 
        partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice <= (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT 
    n.n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC)) AS adjusted_avg_rank
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    FilteredSuppliers fs ON l.l_suppkey = fs.s_suppkey
LEFT JOIN 
    PartSupplierInfo psi ON l.l_partkey = psi.ps_partkey
WHERE 
    l.l_shipdate > '2023-01-01' AND
    l.l_returnflag = 'N' AND
    EXISTS (SELECT 1 FROM RankedOrders ro WHERE ro.o_orderkey = o.o_orderkey AND ro.order_rank <= 10)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    revenue DESC;
