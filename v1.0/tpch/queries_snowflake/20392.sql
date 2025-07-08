
WITH RECURSIVE part_costs AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
customer_orders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
), 
nation_supplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    pc.total_cost,
    co.order_count,
    co.avg_order_value,
    ns.avg_supplier_balance
FROM 
    nation_supplier ns
LEFT JOIN 
    part_costs pc ON ns.n_nationkey = (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps)
        ORDER BY RANDOM() LIMIT 1
    ) 
LEFT JOIN 
    customer_orders co ON co.o_custkey IN (
        SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'O' 
        AND o.o_orderdate >= (DATE '1998-10-01' - INTERVAL '1 year')
    )
WHERE 
    ns.avg_supplier_balance > (
        SELECT AVG(ns2.avg_supplier_balance) 
        FROM nation_supplier ns2 
        WHERE ns2.n_name IS NOT NULL
    ) 
OR (
    EXISTS (
        SELECT 1 
        FROM part p 
        WHERE p.p_retailprice IS NULL
    ) AND ns.n_nationkey IN (SELECT DISTINCT n2.n_nationkey FROM nation n2 WHERE n2.n_comment LIKE '%preferred%')
)
ORDER BY 
    pc.total_cost DESC, 
    co.avg_order_value ASC 
FETCH FIRST 10 ROWS ONLY;
