WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_phone, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),

PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, ps.ps_availqty, ps.ps_supplycost, 
           CONCAT(p.p_name, ' | ', p.p_brand, ' | Price: ', FORMAT(p.p_retailprice, 2), ' | Availability: ', ps.ps_availqty) AS part_info
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),

OrderSummary AS (
    SELECT o.o_orderkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, c.c_name
)

SELECT 
    sd.s_name AS supplier_name,
    sd.nation_name,
    pd.part_info,
    os.c_name AS customer_name,
    os.total_revenue,
    'Region: ' || (SELECT r.r_name FROM region r WHERE r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = sd.nation_name)) AS region_name
FROM SupplierDetails sd
CROSS JOIN PartDetails pd
JOIN OrderSummary os ON os.total_revenue > 10000
WHERE sd.s_acctbal > 5000
ORDER BY sd.s_name, os.total_revenue DESC;
