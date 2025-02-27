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
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        STRING_AGG(DISTINCT l.l_shipmode, ', ') AS ship_modes
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT ns.n_nationkey) AS nation_count,
    SUM(cs.total_spent) AS total_sales,
    AVG(ss.total_supply_value) AS avg_supply_value
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps
        WHERE 
            ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100)
        LIMIT 1
    )
LEFT JOIN 
    CustomerSales cs ON cs.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_mktsegment = 'BUILDING'
    )
WHERE 
    ns.n_comment IS NOT NULL 
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT ns.n_nationkey) > 1
ORDER BY 
    total_sales DESC;