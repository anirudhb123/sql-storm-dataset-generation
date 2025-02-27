WITH RECURSIVE PriceCTE AS (
    SELECT 
        p_partkey,
        p_retailprice,
        p_mfgr,
        p_name,
        1 AS level
    FROM 
        part
    WHERE 
        p_retailprice > (SELECT AVG(p_retailprice) FROM part) 

    UNION ALL

    SELECT 
        p.partkey,
        p.p_retailprice,
        p.p_mfgr,
        p.p_name,
        cte.level + 1
    FROM 
        part p
    INNER JOIN PriceCTE cte ON p.p_retailprice < cte.p_retailprice
    WHERE 
        cte.level < 5
),
NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
OrderAmount AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
FilteredOrders AS (
    SELECT 
        oa.o_orderkey, 
        oa.total_amount,
        ROW_NUMBER() OVER (PARTITION BY oa.o_orderdate ORDER BY oa.total_amount DESC) AS rn
    FROM 
        OrderAmount oa
    WHERE 
        oa.total_amount > 1000
)
SELECT 
    p.p_name,
    p.p_mfgr,
    ps.ps_supplycost,
    ns.n_name,
    ns.supplier_count,
    ps.ps_availqty,
    (SELECT COUNT(*)
     FROM lineitem l
     WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R') AS return_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    NationSummary ns ON s.s_nationkey = ns.s_nationkey
WHERE 
    p.p_retailprice IN (SELECT p_retailprice FROM PriceCTE WHERE level = 2)
    AND ns.supplier_count IS NOT NULL
ORDER BY 
    p.p_name, ps.ps_supplycost DESC;
