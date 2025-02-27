WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS level,
        CAST(s.s_name AS varchar(255)) AS path
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
    
    UNION ALL
    
    SELECT 
        ps.ps_suppkey,
        sc.s_name,
        sc.s_acctbal,
        level + 1,
        CAST(concat(sc.path, ' -> ', p.p_name) AS varchar(255))
    FROM 
        SupplyChain sc
    JOIN 
        partsupp ps ON ps.ps_suppkey = sc.s_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 50
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)

SELECT 
    n.n_name AS Nation,
    COUNT(DISTINCT c.c_custkey) AS CustomerCount,
    AVG(sp.total_supply_cost) AS AvgSupplyCost,
    MAX(ro.total_revenue) AS MaxOrderRevenue,
    ARRAY_AGG(DISTINCT sc.path) AS SupplierPaths
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierPerformance sp ON sp.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = n.n_nationkey)
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN customer c2 ON o.o_custkey = c2.c_custkey WHERE c2.c_nationkey = n.n_nationkey)
LEFT JOIN 
    SupplyChain sc ON sc.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20))
GROUP BY 
    n.n_name
ORDER BY 
    Nation;
