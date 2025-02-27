WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
part_supplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
customer_info AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(n.n_name, 'Unknown') AS nation_name,
        SUM(CASE WHEN l.l_returnflag = 'Y' THEN l.l_quantity ELSE NULL END) AS return_qty
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, n.n_name
),
premium_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_value
    FROM part p
    JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100.00
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_size
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 1
)
SELECT 
    co.c_name,
    pp.p_name,
    pp.p_brand,
    pp.supplier_count,
    pp.supply_value,
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderstatus
FROM customer_info co
JOIN premium_parts pp ON co.c_custkey IN (
    SELECT c.c_custkey FROM customer c 
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
)
LEFT JOIN ranked_orders r ON r.o_orderkey = (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_custkey = co.c_custkey 
    AND o.o_orderstatus = 'O' 
    ORDER BY o.o_orderdate DESC 
    LIMIT 1
)
WHERE pp.supply_value > 100000
ORDER BY co.c_name, pp.p_name
FETCH FIRST 100 ROWS ONLY;
