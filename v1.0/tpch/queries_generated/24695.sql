WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 20)
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') -- Only open or finalized orders
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name
    FROM 
        nation n
    WHERE 
        n.n_regionkey IN (
            SELECT r.r_regionkey FROM region r WHERE r.r_comment IS NOT NULL
        )
),
FinalResults AS (
    SELECT 
        P.p_name,
        S.s_name,
        C.c_name,
        COALESCE(CU.order_count, 0) AS order_count,
        COALESCE(SI.total_supply_value, 0) AS total_supply_value
    FROM 
        RankedParts P
    LEFT JOIN 
        SupplierInfo SI ON P.p_partkey = SI.supplied_parts 
    LEFT JOIN 
        CustomerOrders CU ON CU.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal > 5000 LIMIT 1)
    JOIN 
        FilteredNations FN ON FN.n_nationkey = (SELECT n.n_nationkey FROM nation n ORDER BY RANDOM() LIMIT 1)
)
SELECT 
    *
FROM 
    FinalResults
WHERE 
    total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierInfo)
ORDER BY 
    order_count DESC, total_supply_value ASC
LIMIT 100;
