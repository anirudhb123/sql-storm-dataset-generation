WITH RECURSIVE supplier_rank AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), expensive_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           CASE 
               WHEN p.p_retailprice > 500 THEN 'EXPENSIVE'
               ELSE 'AFFORDABLE' 
           END AS price_category
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
), customer_orders AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), detailed_lineitems AS (
    SELECT l.*, 
           ROUND(l.l_extendedprice * (1 - l.l_discount), 2) AS net_price,
           EXTRACT(YEAR FROM l.l_shipdate) AS ship_year
    FROM lineitem l
    WHERE l.l_shipdate IS NOT NULL 
), nation_summary AS (
    SELECT n.n_nationkey, n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
), top_suppliers AS (
    SELECT ns.n_nationkey, ns.n_name, sr.s_name, sr.s_acctbal
    FROM nation_summary ns
    JOIN supplier_rank sr ON ns.supplier_count > 0 AND sr.rank <= 3
)

SELECT 
    p.p_name, 
    p.p_retailprice, 
    COALESCE(c.order_count, 0) AS total_orders,
    COALESCE(c.total_spent, 0.00) AS total_spent,
    COALESCE(ts.s_name, 'Unknown Supplier') AS top_supplier_name,
    CASE 
        WHEN p.p_retailprice IS NULL THEN 'NO PRICE'
        WHEN p.p_retailprice > 1000 THEN 'OVER THE TOP'
        ELSE 'BARGAIN DEAL'
    END AS pricing_status,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(ts.n_nationkey, -1) ORDER BY p.p_retailprice DESC) AS price_rank
FROM expensive_parts p
LEFT JOIN customer_orders c ON c.total_spent > 0 
LEFT JOIN top_suppliers ts ON ts.s_nationkey = (
    SELECT n.n_nationkey
    FROM nation n
    WHERE n.n_name LIKE '%land%' LIMIT 1
)
ORDER BY p.p_retailprice DESC NULLS LAST;
