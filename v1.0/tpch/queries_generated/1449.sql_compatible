
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CTE_PartStats.p_name,
        CTE_PartStats.total_quantity,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN (
        SELECT 
            l.l_orderkey,
            p.p_name,
            SUM(l.l_quantity) AS total_quantity
        FROM 
            lineitem l 
        JOIN 
            partsupp ps ON l.l_partkey = ps.ps_partkey
        JOIN 
            part p ON ps.ps_partkey = p.p_partkey
        GROUP BY 
            l.l_orderkey, p.p_name
    ) AS CTE_PartStats ON o.o_orderkey = CTE_PartStats.l_orderkey
),
SupplierRegions AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_suppkey,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name, s.s_suppkey
)
SELECT 
    R.o_orderkey,
    R.o_totalprice,
    R.o_orderdate,
    R.p_name,
    R.total_quantity,
    S.nation_name,
    S.region_name,
    S.total_acctbal
FROM 
    RankedOrders R
FULL OUTER JOIN 
    SupplierRegions S ON (R.o_orderkey IS NULL OR S.s_suppkey IS NULL)
WHERE 
    (R.rn = 1 OR R.rn IS NULL)
    AND (S.total_acctbal > 1000 OR S.total_acctbal IS NULL);
