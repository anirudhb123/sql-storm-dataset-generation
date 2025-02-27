WITH RankedParts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_brand,
           p.p_type,
           p.p_comment,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_name LIKE '%steel%'
),
NationSupplier AS (
    SELECT n.n_name,
           s.s_name,
           s.s_acctbal,
           SUM(ps.ps_availqty) AS total_available_qty
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, s.s_name, s.s_acctbal
    HAVING SUM(ps.ps_availqty) > 5000
),
TopCustomers AS (
    SELECT c.c_name,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT rp.p_name,
       rp.p_brand,
       rp.p_type,
       ns.n_name,
       ns.s_name,
       ns.total_available_qty,
       tc.c_name,
       tc.total_spent
FROM RankedParts rp
JOIN NationSupplier ns ON ns.total_available_qty > 1000
JOIN TopCustomers tc ON tc.total_spent > 15000
WHERE rp.rn = 1
ORDER BY rp.p_brand, ns.n_name, tc.total_spent DESC;
