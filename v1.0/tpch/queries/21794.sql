WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rnk,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
        COALESCE(AVG(ps.ps_supplycost), 0) AS avg_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighlyValuedParts AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.total_avail_qty,
        pd.avg_supplycost
    FROM PartDetails pd
    WHERE pd.total_avail_qty > (
        SELECT AVG(total_avail_qty)
        FROM PartDetails
    ) AND pd.avg_supplycost < (
        SELECT AVG(avg_supplycost)
        FROM PartDetails
    )
),
HighValueCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.order_count,
        CASE 
            WHEN co.total_spent > 10000 THEN 'VIP'
            ELSE 'Regular'
        END AS customer_status
    FROM CustomerOrders co
    WHERE co.order_count > 5
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    s.s_name AS supplier_name,
    pp.p_name AS part_name,
    c.c_name AS customer_name,
    cvc.customer_status,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM region r
JOIN nation ns ON r.r_regionkey = ns.n_regionkey
JOIN supplier s ON ns.n_nationkey = s.s_nationkey
JOIN HighlyValuedParts pp ON s.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pp.p_partkey
)
JOIN lineitem l ON s.s_suppkey = l.l_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN HighValueCustomers cvc ON o.o_custkey = cvc.c_custkey
JOIN customer c ON c.c_custkey = o.o_custkey
WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY r.r_name, ns.n_name, s.s_name, pp.p_name, c.c_name, cvc.customer_status
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000 
   OR cvc.customer_status = 'VIP'
ORDER BY region_name, nation_name, supplier_name, customer_name;