WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
), product_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY (p.p_retailprice - ps.ps_supplycost) DESC) AS rank_margin
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
), correlated_sums AS (
    SELECT 
        co.c_custkey,
        SUM(co.o_totalprice) OVER (PARTITION BY co.c_custkey) AS total_spent,
        COUNT(co.o_orderkey) OVER (PARTITION BY co.c_custkey) AS order_count
    FROM customer_orders co
    WHERE co.rn = 1
)
SELECT 
    c.c_custkey,
    c.c_name,
    CASE 
        WHEN cs.total_spent > 10000 THEN 'High Value'
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE 'Regular'
    END AS customer_type,
    pd.p_name,
    pd.profit_margin,
    pd.rank_margin
FROM customer c
LEFT JOIN correlated_sums cs ON c.c_custkey = cs.c_custkey
LEFT JOIN product_details pd ON c.c_custkey IN (
    SELECT DISTINCT l.l_orderkey 
    FROM lineitem l 
    INNER JOIN orders o ON l.l_orderkey = o.o_orderkey 
    WHERE o.o_orderstatus = 'O' 
    AND l.l_returnflag = 'N'
) AND pd.rank_margin <= 3
ORDER BY c.c_custkey, pd.profit_margin DESC NULLS LAST;
