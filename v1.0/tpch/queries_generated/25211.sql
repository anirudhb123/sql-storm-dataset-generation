WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
           s.s_comment
    FROM supplier s
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, ps.ps_availqty, ps.ps_supplycost, 
           CONCAT(p.p_name, ' - ', p.p_brand) AS part_description
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, 
           c.c_comment AS customer_comment, 
           CONCAT(c.c_name, ' [', o.o_orderkey, ']') AS order_info
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT ps.s_suppkey, ps.s_name AS supplier_name, ps.s_comment,
       pd.part_description, co.customer_comment, co.order_info,
       nr.region_name
FROM RankedSuppliers ps
JOIN PartDetails pd ON ps.s_suppkey = pd.ps_suppkey
JOIN CustomerOrders co ON co.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey = pd.p_partkey
)
JOIN NationRegion nr ON ps.s_nationkey = nr.n_nationkey
WHERE ps.rank <= 5
ORDER BY nr.region_name, ps.s_suppkey;
