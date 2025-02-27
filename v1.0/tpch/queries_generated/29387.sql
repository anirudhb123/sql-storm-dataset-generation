WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment,
           REPLACE(REPLACE(s.s_address, 'Street', 'St'), 'Avenue', 'Ave') AS formatted_address
    FROM supplier s
),
RegionDetails AS (
    SELECT r.r_regionkey, r.r_name,
           CONCAT('Region: ', r.r_name, ' - ', r.r_comment) AS region_info
    FROM region r
),
PartPopularity AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available,
           COUNT(ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerActivity AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT s.s_name AS supplier_name,
       r.region_info,
       p.p_name AS part_name,
       p.p_brand,
       c.c_name AS customer_name,
       ca.order_count,
       ca.total_spent,
       pa.total_available,
       pa.supplier_count,
       'Total products available: ' || pa.total_available AS availability_message
FROM SupplierDetails s
JOIN RegionDetails r ON s.s_nationkey = r.r_regionkey
JOIN PartPopularity pa ON pa.ps_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = s.s_suppkey ORDER BY ps_availqty DESC LIMIT 1)
JOIN customer c ON s.s_nationkey = c.c_nationkey
JOIN CustomerActivity ca ON c.c_custkey = ca.c_custkey
WHERE ca.order_count > 5
ORDER BY ca.total_spent DESC, s.s_name;
