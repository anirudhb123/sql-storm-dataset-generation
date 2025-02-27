WITH RankedParts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_mfgr,
           p.p_brand,
           p.p_type,
           p.p_size,
           p.p_container,
           p.p_retailprice,
           p.p_comment,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
),
SupplierStats AS (
    SELECT s.s_nationkey,
           COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           AVG(s.s_acctbal) AS average_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name AS region_name,
       n.n_name AS nation_name,
       COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
       SUM(CASE WHEN rp.rank <= 3 THEN rp.p_retailprice ELSE 0 END) AS top_retail_price_sum,
       AVG(cs.total_spent) AS avg_customer_spent,
       MIN(cs.total_orders) AS min_orders_by_customer
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey
JOIN CustomerOrders cs ON cs.total_orders > 0
GROUP BY r.r_name, n.n_name
ORDER BY region_name, nation_name;
