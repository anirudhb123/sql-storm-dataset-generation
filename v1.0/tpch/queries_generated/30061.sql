WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_retailprice, 
           CASE 
               WHEN p_size IS NULL THEN 'Unknown' 
               ELSE CAST(p_size AS VARCHAR) 
           END AS size_info
    FROM part
    WHERE p_size IS NOT NULL
  
    UNION ALL
  
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           CASE 
               WHEN p.p_size IS NULL THEN 'Unknown' 
               ELSE CAST(p.p_size AS VARCHAR) 
           END AS size_info
    FROM part p
    JOIN part_hierarchy ph ON p.p_partkey = ph.p_partkey + 1
),
nation_supply AS (
    SELECT n.n_name, SUM(ps.ps_availqty) AS total_avail_qty, 
           SUM(ps.ps_supplycost) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, n.n_nationkey
),
date_filtered_orders AS (
    SELECT o.o_orderkey, o.o_custkey, 
           DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank,
           o.o_totalprice
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
)
SELECT ph.p_name, ph.size_info, 
       ns.n_name, ns.total_avail_qty,
       do.o_orderkey, do.order_rank, do.o_totalprice
FROM part_hierarchy ph
LEFT JOIN nation_supply ns ON ns.rn = 1
LEFT JOIN date_filtered_orders do ON do.o_custkey = (SELECT c.c_custkey
                                                       FROM customer c
                                                       WHERE c.c_name LIKE '%' || ns.n_name || '%')
WHERE ph.p_retailprice > 100
  AND ns.total_supply_cost IS NOT NULL
ORDER BY ns.total_avail_qty DESC, ph.p_name;
