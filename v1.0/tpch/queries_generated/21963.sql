WITH RankedSuppliers AS (
    SELECT 
        ps.suppkey,
        ps.partkey,
        ps.availqty,
        ps.supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.partkey ORDER BY ps.availqty DESC, ps.supplycost ASC) AS rn
    FROM partsupp ps
    WHERE ps.availqty > 0
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey
    HAVING COUNT(n.n_nationkey) > 3
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        (CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown Balance'
            WHEN s.s_acctbal > 5000 THEN 'High Value Supplier'
            ELSE 'Regular Supplier' 
         END) AS supplier_type
    FROM supplier s
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_retailprice,
    COALESCE(AVG(s.supplycost), 0) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MIN(h.total_sales) AS min_order_sales,
    CASE 
        WHEN COUNT(DISTINCT h.o_orderkey) > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer' 
    END AS buyer_category
FROM part p
LEFT JOIN RankedSuppliers rs ON p.p_partkey = rs.partkey AND rs.rn = 1
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN HighValueOrders h ON h.o_custkey = l.l_suppkey
JOIN SupplierDetails s ON s.s_suppkey = rs.suppkey
JOIN TopRegions tr ON tr.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice
ORDER BY p.p_retailprice DESC, total_orders DESC;
