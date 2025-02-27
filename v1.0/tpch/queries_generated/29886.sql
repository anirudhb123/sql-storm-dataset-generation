WITH PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_container,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_avail_qty,
           STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers_list
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_container
),
PopularBrands AS (
    SELECT p.p_brand,
           COUNT(DISTINCT p.p_partkey) AS brand_part_count
    FROM part p
    GROUP BY p.p_brand
    HAVING COUNT(DISTINCT p.p_partkey) > 5
)
SELECT r.r_name AS region, 
       n.n_name AS nation, 
       c.c_name AS customer, 
       pd.p_name AS part_name,
       pd.supplier_count, 
       pd.total_avail_qty, 
       pb.brand_part_count,
       pd.suppliers_list
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN customer c ON s.s_suppkey = c.c_nationkey
JOIN PartDetails pd ON pd.supplier_count > 2
JOIN PopularBrands pb ON pb.p_brand = pd.p_brand
WHERE c.c_acctbal > 500
ORDER BY r.r_name, n.n_name, c.c_name, pd.p_name;
