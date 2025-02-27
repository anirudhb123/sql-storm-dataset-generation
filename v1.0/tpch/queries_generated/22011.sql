WITH RECURSIVE SupplierCTE AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING total_supply_cost > 10000
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        (CASE 
            WHEN SUM(o.o_totalprice) IS NULL THEN 'DEFAULT'
            WHEN SUM(o.o_totalprice) > 5000 THEN 'VIP'
            ELSE 'Regular' 
         END) AS customer_type
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM partsupp ps
),
FilteredDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        cs.customer_type
    FROM HighValueParts p
    LEFT JOIN PartSupplierDetails ps ON p.p_partkey = ps.ps_partkey AND ps.rn = 1
    LEFT JOIN SupplierCTE s ON ps.ps_suppkey = s.s_suppkey AND s.rank <= 3
    LEFT JOIN CustomerOrderSummary cs ON cs.total_orders > 3
)
SELECT
    fd.p_partkey,
    fd.p_name,
    fd.supplier_name,
    fd.ps_availqty,
    fd.ps_supplycost,
    fd.customer_type
FROM FilteredDetails fd
WHERE fd.ps_supplycost IS NOT NULL
  AND (fd.customer_type = 'VIP' OR fd.customer_type = 'Regular')
ORDER BY fd.ps_supplycost DESC, fd.p_name ASC;
