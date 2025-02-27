WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn,
        CASE 
            WHEN p.p_size IS NULL THEN 'UNKNOWN' 
            ELSE CONCAT('Size: ', CAST(p.p_size AS VARCHAR))
        END AS size_description
    FROM part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS average_account_balance
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1)
    GROUP BY c.c_custkey
),
NationDetails AS (
    SELECT 
        n.n_nationkey, 
        MAX(n.n_name) AS nation_name,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.size_description,
    ss.total_parts,
    ss.total_supply_cost,
    cos.order_count,
    cos.total_spent,
    cos.last_order_date,
    nd.nation_name,
    nd.suppliers,
    CASE 
        WHEN cos.total_spent IS NULL THEN 0 
        ELSE cos.total_spent / NULLIF(cos.order_count, 0)
    END AS avg_spent_per_order
FROM RankedParts rp
FULL OUTER JOIN SupplierStats ss ON ss.total_parts > 5
JOIN CustomerOrderStats cos ON cos.order_count > 3
JOIN NationDetails nd ON nd.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1 LIMIT 1)
WHERE rp.rn <= 10
    AND rp.p_retailprice BETWEEN 100 AND 500
ORDER BY rp.p_retailprice DESC, cos.total_spent ASC;
