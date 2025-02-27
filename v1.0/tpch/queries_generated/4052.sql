WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 5000
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_orders,
        cust.order_count,
        ROW_NUMBER() OVER (ORDER BY cust.total_orders DESC) AS rank
    FROM CustomerOrderSummary cust
    WHERE cust.total_orders IS NOT NULL
    AND cust.order_count > 3
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    c.c_name AS customer_name,
    c.total_orders,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS price_rank
FROM part p
LEFT JOIN RankedSupplier s ON s.s_suppkey = (
    SELECT TOP 1 s_sub.s_suppkey 
    FROM supplier s_sub 
    JOIN partsupp ps_sub ON s_sub.s_suppkey = ps_sub.ps_suppkey 
    WHERE ps_sub.ps_partkey = p.p_partkey 
    ORDER BY s_sub.s_acctbal DESC
)
LEFT JOIN TopCustomers c ON c.cust.c_custkey IN (
    SELECT DISTINCT o.o_custkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_partkey = p.p_partkey
)
WHERE p.p_size BETWEEN 10 AND 50
ORDER BY p.p_partkey, price_rank;
