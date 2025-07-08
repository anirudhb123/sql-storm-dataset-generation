
WITH RECURSIVE SupplierHiearchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHiearchy sh ON s.s_nationkey = sh.s_suppkey
),
OrderRevenue AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(sp.supplier_count, 0) AS supplier_count
    FROM part p
    LEFT JOIN SupplierPartCount sp ON p.p_partkey = sp.ps_partkey
)
SELECT 
    r.r_name,
    pd.p_name,
    pd.p_brand,
    pd.p_retailprice,
    pd.supplier_count,
    tr.total_revenue,
    tc.c_name AS top_customer,
    tc.total_spent
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN PartDetails pd ON n.n_nationkey = pd.p_partkey
LEFT JOIN OrderRevenue tr ON tr.o_orderkey = pd.p_partkey
LEFT JOIN TopCustomers tc ON tc.customer_rank <= 10
WHERE pd.supplier_count > 5
ORDER BY tr.total_revenue DESC NULLS LAST;
