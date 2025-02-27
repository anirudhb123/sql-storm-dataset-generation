WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrdersWithHighValue AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_quantity > 0
        AND o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND s.s_acctbal >= 100.00
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 1
),
FinalResults AS (
    SELECT
        RANK() OVER (ORDER BY pa.total_availqty DESC) AS availability_rank,
        na.n_name, 
        sp.s_name,
        pp.p_name,
        pp.p_retailprice,
        oh.total_order_value,
        CASE 
            WHEN oh.total_order_value IS NULL THEN 'No Orders'
            ELSE 'Has Orders'
        END AS order_status
    FROM 
        RankedParts pp
    JOIN 
        SupplierAvailability pa ON pp.p_partkey = pa.ps_partkey
    LEFT JOIN 
        FilteredSuppliers sp ON pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.s_suppkey)
    LEFT JOIN 
        OrdersWithHighValue oh ON oh.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_comment LIKE '%global%'))
    LEFT JOIN 
        nation na ON sp.s_nationkey = na.n_nationkey
)
SELECT 
    availability_rank,
    n_name AS supplier_nation,
    s_name AS supplier_name,
    p_name AS part_name,
    p_retailprice,
    total_order_value,
    order_status
FROM 
    FinalResults
WHERE 
    p_retailprice < (SELECT MAX(p2.p_retailprice) FROM part p2 WHERE p2.p_brand = 'Brand#35')
ORDER BY 
    availability_rank, p_retailprice DESC
FETCH FIRST 50 ROWS ONLY;
