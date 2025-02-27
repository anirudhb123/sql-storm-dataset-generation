WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_status
    FROM orders o
    WHERE o.o_orderdate > '1995-01-01'
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS count_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
), 
HighValueCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS cust_rank
    FROM CustomerSummary cs
    WHERE cs.total_spent > 1000
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sd.count_parts, 0) AS parts_supplied,
    COALESCE(hvc.total_spent, 0) AS customer_spending
FROM part p
LEFT JOIN SupplierDetails sd ON sd.count_parts = (
    SELECT MAX(count_parts) 
    FROM SupplierDetails 
    WHERE count_parts IS NOT NULL
)
LEFT JOIN HighValueCustomers hvc ON hvc.cust_rank = 1
WHERE p.p_retailprice BETWEEN 10.00 AND 100.00
ORDER BY p.p_partkey DESC
UNION ALL 
SELECT 
    NULL AS partkey,
    'Total Sum' AS part_name,
    COUNT(p.p_partkey) AS parts_supplied,
    SUM(hvc.total_spent) AS customer_spending
FROM part p
LEFT JOIN HighValueCustomers hvc ON hvc.total_spent IS NOT NULL
HAVING COUNT(p.p_partkey) > 0
ORDER BY parts_supplied DESC;
