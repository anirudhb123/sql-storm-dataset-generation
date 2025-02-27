WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-06-01' AND DATE '1996-07-01'
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(rs.order_rank, 0) AS order_rank,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(fl.net_revenue, 0) AS net_revenue
FROM 
    part p
LEFT JOIN 
    RankedOrders rs ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE'))) AND ROWNUM = 1
LEFT JOIN 
    SupplierSummary ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN 
    FilteredLineItems fl ON fl.l_partkey = p.p_partkey
WHERE 
    (p.p_retailprice IS NULL OR p.p_retailprice > 100)
    AND EXISTS (SELECT 1 FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = fl.l_orderkey AND fl.l_orderkey IS NOT NULL LIMIT 1))
ORDER BY 
    p.p_partkey DESC
FETCH FIRST 10 ROWS ONLY;
