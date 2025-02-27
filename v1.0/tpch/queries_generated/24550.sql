WITH RECURSIVE supplier_data AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), customer_orders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
), nation_performance AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(co.total_spent) AS total_income
    FROM nation n
    LEFT JOIN customer_orders co ON n.n_nationkey = co.c_nationkey
    JOIN customer c ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
), high_value_suppliers AS (
    SELECT sd.s_name, n.r_name, sd.s_acctbal
    FROM supplier_data sd
    JOIN nation n ON sd.s_nationkey = n.n_nationkey
    WHERE sd.rank <= 3
), income_analysis AS (
    SELECT n.n_name, 
           COALESCE(SUM(hi.s_acctbal), 0) AS total_supplier_acctbal,
           COUNT(DISTINCT co.c_custkey) AS unique_customers
    FROM nation n
    LEFT JOIN high_value_suppliers hi ON n.n_name = hi.r_name
    LEFT JOIN customer_orders co ON n.n_nationkey = co.c_nationkey
    GROUP BY n.n_name
) 
SELECT n.n_name,
       np.customer_count,
       np.total_income,
       ia.total_supplier_acctbal,
       ia.unique_customers,
       CASE 
           WHEN np.total_income IS NULL THEN 'No income'
           WHEN ia.total_supplier_acctbal > np.total_income THEN 'Suppliers dominate'
           ELSE 'Income is high'
       END AS income_comment
FROM nation_performance np
JOIN income_analysis ia ON np.n_name = ia.n.n_name
ORDER BY np.total_income DESC, ia.total_supplier_acctbal DESC
FETCH FIRST 10 ROWS ONLY;

-- With a focus on prices and suppliers, this aggregate output helps benchmark performance across nations
