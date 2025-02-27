WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) as total_parts,
        SUM(ps.ps_supplycost) as total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost) DESC) as rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        orders o
    WHERE 
        o.o_totalprice IS NOT NULL AND 
        o.o_orderdate >= DATEADD(DAY, -30, GETDATE())
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND 
        c.c_mktsegment = 'BUILDING'
)
SELECT 
    rnk,
    ss.s_name AS supplier_name,
    hs.c_name AS customer_name,
    fo.o_orderdate,
    fo.o_totalprice
FROM 
    RankedSuppliers ss
FULL OUTER JOIN 
    FilteredOrders fo ON ss.total_parts = (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = fo.o_orderkey)
LEFT JOIN 
    HighValueCustomers hs ON hs.c_custkey = fo.o_custkey
WHERE 
    ss.total_supplycost IS NOT NULL 
    AND (fo.o_orderdate IS NOT NULL OR hs.customer_rank IS NOT NULL)
    AND ss.rnk <= 5
ORDER BY 
    ss.total_supplycost DESC, 
    fo.o_orderdate DESC
LIMIT 100;
