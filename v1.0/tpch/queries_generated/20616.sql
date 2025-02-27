WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    WHERE o.o_totalprice > 0
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name,
        COUNT(ps.ps_availqty) AS available_parts
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, r.r_name
),
CustomerPurchaseSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
),
Details AS (
    SELECT 
        so.o_orderkey, 
        rd.s_name AS supplier_name, 
        cp.total_orders, 
        cp.total_spent,
        COALESCE(cp.total_spent / NULLIF(cp.total_orders, 0), 0) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY so.o_orderkey ORDER BY so.o_orderdate DESC) AS order_details_rank
    FROM RankedOrders so
    LEFT JOIN lineitem li ON so.o_orderkey = li.l_orderkey
    LEFT JOIN SupplierDetails rd ON li.l_suppkey = rd.s_suppkey
    JOIN CustomerPurchaseSummary cp ON so.o_custkey = cp.c_custkey
)
SELECT 
    d.o_orderkey,
    d.supplier_name AS supplier,
    d.total_orders,
    d.total_spent,
    d.avg_order_value,
    CASE 
        WHEN d.avg_order_value > 100 THEN 'High Value'
        WHEN d.avg_order_value BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS order_value_category,
    r.r_name AS region,
    COALESCE(SUM(l.l_discount) OVER (PARTITION BY d.o_orderkey), 0) AS total_discount
FROM Details d
LEFT JOIN lineitem l ON d.o_orderkey = l.l_orderkey
LEFT JOIN supplier s ON d.supplier_name = s.s_name
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE d.order_details_rank = 1
  AND d.total_spent IS NOT NULL
ORDER BY d.o_orderkey, d.total_spent DESC;
