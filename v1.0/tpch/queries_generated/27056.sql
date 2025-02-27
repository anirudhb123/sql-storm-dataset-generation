WITH PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_mfgr, 
           p.p_brand, 
           p.p_type, 
           p.p_size, 
           p.p_container, 
           p.p_retailprice, 
           p.p_comment,
           COUNT(DISTINCT ps.ps_suppkey) AS supply_count,
           STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent,
           STRING_AGG(DISTINCT o.o_orderstatus, ', ') AS order_statuses
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 500
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 3
)
SELECT pd.*, 
       co.c_name AS customer_name, 
       co.order_count, 
       co.total_spent, 
       co.order_statuses
FROM PartDetails pd
JOIN CustomerOrders co ON pd.supplier_names LIKE '%' || co.c_name || '%'
ORDER BY pd.p_retailprice DESC, co.total_spent DESC;
