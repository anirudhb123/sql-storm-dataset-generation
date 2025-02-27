WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice > 100.00
),
TopNations AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 5
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000.00
)
SELECT 
    r.r_name AS region,
    tn.n_name AS nation,
    p.p_name AS part_name,
    dsp.c_name AS customer_name,
    dsp.total_spent AS total_spent,
    MAX(p.p_retailprice) AS max_retail_price
FROM RankedParts p
JOIN TopNations tn ON tn.supplier_count > 0
JOIN region r ON r.r_regionkey = tn.n_regionkey
JOIN CustomerSpending dsp ON dsp.total_spent > 5000.00
WHERE p.rn <= 5
GROUP BY r.r_name, tn.n_name, p.p_name, dsp.c_name, dsp.total_spent
ORDER BY region, nation, part_name;
