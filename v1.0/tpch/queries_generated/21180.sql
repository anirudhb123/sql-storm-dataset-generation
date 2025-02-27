WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rnk,
        (SELECT SUM(s.s_acctbal) 
         FROM supplier s 
         WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')) AS total_us_acctbal
    FROM partsupp ps
), FilteredSuppliers AS (
    SELECT 
        rs.ps_partkey, 
        rs.ps_suppkey, 
        rs.ps_availqty, 
        rs.ps_supplycost,
        CASE 
            WHEN rs.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp) THEN 'Below Average' 
            ELSE 'Above Average' 
        END AS cost_category
    FROM RankedSuppliers rs
    WHERE rs.rnk <= 3 AND rs.ps_availqty > 0
), OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts_count,
        o.o_orderdate,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey, o.o_orderdate
), CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), SupplierRegionData AS (
    SELECT 
        s.s_name,
        r.r_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY s.s_name, r.r_name
)
SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(oc.order_count, 0) AS order_count,
    COALESCE(oc.max_order_value, 0) AS max_order_value,
    fr.ps_partkey,
    fr.ps_supplycost,
    srd.total_avail_qty,
    srd.unique_parts_supplied,
    fr.cost_category,
    rs.total_us_acctbal,
    CASE 
        WHEN fr.ps_supplycost IS NULL THEN 'No Supplier Available' 
        ELSE 'Supplier Found' 
    END AS supplier_status
FROM customer c
LEFT JOIN CustomerOrderCounts oc ON c.c_custkey = oc.c_custkey
LEFT JOIN FilteredSuppliers fr ON fr.ps_partkey IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 1000)
LEFT JOIN SupplierRegionData srd ON srd.s_name = fr.ps_suppkey 
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
ORDER BY c.c_name, fr.ps_supplycost DESC;
