WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size > (SELECT AVG(p2.p_size) FROM part p2 WHERE p2.p_type LIKE '%metal%')
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey
    FROM 
        SupplierStats ss
    WHERE 
        ss.unique_parts > (SELECT AVG(unique_parts) FROM SupplierStats) 
        AND ss.total_supply_value > 1000000
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        np.n_name AS nation_name,
        p.p_name,
        rp.rank,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        region r
    JOIN nation np ON r.r_regionkey = np.n_regionkey
    LEFT JOIN supplier s ON np.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey
    LEFT JOIN CustomerOrders co ON s.s_suppkey = co.c_custkey
    WHERE 
        rp.rank <= 3
    AND 
        s.s_acctbal IS NOT NULL 
    AND 
        (rp.p_retailprice - co.total_spent) > 50.00
    GROUP BY 
        r.r_name, np.n_name, p.p_name, rp.rank
)
SELECT 
    fr.region_name,
    fr.nation_name,
    fr.p_name,
    fr.rank,
    COALESCE(fr.customer_count, 0) AS total_customers
FROM 
    FinalReport fr
FULL OUTER JOIN SupplierStats ss ON fr.customer_count = NULL OR ss.unique_parts IS NULL
ORDER BY 
    fr.region_name, fr.nation_name, fr.rank;
