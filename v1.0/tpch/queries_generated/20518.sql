WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_desc,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice ASC) AS rank_asc
    FROM part p
), 
TopExpensiveParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice 
    FROM RankedParts p
    WHERE p.rank_desc <= 10
), 
TopCheapParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice 
    FROM RankedParts p
    WHERE p.rank_asc <= 10
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
), 
SupplierRanking AS (
    SELECT 
        si.s_suppkey,
        si.s_name,
        si.part_count,
        si.total_supplycost,
        RANK() OVER (ORDER BY si.total_supplycost DESC) AS supply_rank
    FROM SupplierInfo si
), 
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        co.order_count,
        NTILE(5) OVER (ORDER BY co.total_spent DESC) AS spending_group
    FROM CustomerOrders co
)
SELECT 
    p.p_name AS expensive_part,
    cp.p_name AS cheap_part,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    s.total_supplycost,
    c.total_spent
FROM TopExpensiveParts p
FULL OUTER JOIN TopCheapParts cp ON p.p_partkey = cp.p_partkey
JOIN SupplierRanking s ON s.part_count > 5
JOIN TopCustomers c ON c.order_count > 3
WHERE (s.total_supplycost IS NULL OR s.total_supplycost > 1000)
AND (c.total_spent IS NOT NULL)
ORDER BY s.total_supplycost DESC, c.total_spent ASC
FETCH FIRST 20 ROWS ONLY;
