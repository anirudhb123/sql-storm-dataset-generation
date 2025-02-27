
WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 20
),
NationSupplier AS (
    SELECT
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        total_orders,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS cust_rank
    FROM CustomerOrders c
    WHERE total_orders > 5
)
SELECT
    np.n_nationkey,
    np.unique_suppliers,
    tp.c_custkey,
    tp.total_orders,
    tp.total_spent,
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    COALESCE(tp.total_spent / NULLIF(tp.total_orders, 0), 0) AS avg_spent_per_order,
    CASE 
        WHEN tp.total_spent IS NULL THEN 'No Orders'
        WHEN tp.total_spent > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM NationSupplier np
FULL OUTER JOIN TopCustomers tp ON np.n_nationkey = (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_nationkey = (SELECT DISTINCT n_regionkey FROM region r WHERE r.r_name LIKE '%east%')
    LIMIT 1
)
JOIN RankedParts rp ON (rp.price_rank <= 3 AND rp.p_retailprice < 200.00)
WHERE np.unique_suppliers IS NOT NULL
ORDER BY np.unique_suppliers DESC, tp.total_spent DESC, rp.p_retailprice ASC;
