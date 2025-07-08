
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
),
HighPriceParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice
    FROM RankedParts rp
    WHERE rp.rn <= 5
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (
        SELECT AVG(total_cost) FROM (
            SELECT SUM(ps_supplycost * ps_availqty) AS total_cost
            FROM supplier s
            JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
            GROUP BY s.s_suppkey
        ) AS avg_cost
    )
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 10 AND SUM(o.o_totalprice) > 1000
)
SELECT 
    co.c_custkey,
    co.c_name,
    hp.p_name,
    hp.p_retailprice,
    ts.s_name,
    ts.total_cost
FROM CustomerOrders co
JOIN HighPriceParts hp ON co.c_custkey = (
    SELECT c.c_custkey 
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE l.l_partkey = hp.p_partkey
    LIMIT 1
)
JOIN TopSuppliers ts ON EXISTS (
    SELECT 1 
    FROM partsupp ps 
    WHERE ps.ps_partkey = hp.p_partkey AND ps.ps_suppkey = ts.s_suppkey
)
ORDER BY co.total_spent DESC, hp.p_retailprice ASC;
