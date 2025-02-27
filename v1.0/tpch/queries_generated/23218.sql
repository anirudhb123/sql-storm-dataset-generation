WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ARRAY_AGG(DISTINCT p.p_name) AS part_names
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        r.r_name
    FROM 
        nation n
    INNER JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(
        STRING_AGG(DISTINCT p.part_name, ', ') FILTER (WHERE p.part_name IS NOT NULL), 
        'No Parts') AS part_names,
    (SELECT SUM(l.l_extendedprice * (1 - l.l_discount))
     FROM lineitem l 
     WHERE l.l_orderkey = o.o_orderkey
       AND l.l_returnflag = 'N') AS net_revenue,
    (SELECT COUNT(DISTINCT s.s_suppkey)
     FROM FilteredSuppliers s
     WHERE EXISTS (
         SELECT 1 
         FROM partsupp ps 
         WHERE ps.ps_suppkey = s.s_suppkey 
           AND ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE 'widget%')
     )
    ) AS supplier_count
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    o.order_rank <= 10
    AND EXISTS (SELECT 1 FROM NationRegion nr WHERE nr.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey))
GROUP BY 
    o.o_orderkey, o.o_orderdate
ORDER BY 
    o.o_orderdate DESC, net_revenue DESC;
