WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown' 
            ELSE CAST(p.p_size AS varchar) || ' units'
        END AS size_description
    FROM part p
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
        WHERE p2.p_brand IS NOT NULL
    )
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price,
        COUNT(DISTINCT l.l_orderkey) AS num_lineitems
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    s.s_name AS supplier_name,
    fp.total_available,
    os.total_lineitem_price,
    CASE 
        WHEN os.total_lineitem_price IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    'Size: ' || COALESCE(fp.size_description, 'N/A') AS part_size_info
FROM FilteredParts fp
LEFT OUTER JOIN SupplierPartStats ps ON fp.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rn = 1
JOIN OrderStats os ON os.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_totalprice > os.o_totalprice)
WHERE (fp.p_retailprice NOT BETWEEN 100 AND 500 OR fp.p_retailprice IS NULL)
ORDER BY p.p_partkey DESC, s.s_name ASC;
