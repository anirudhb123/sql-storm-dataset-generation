WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
TopCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.avg_order_value,
        cs.order_count,
        RANK() OVER (ORDER BY cs.avg_order_value DESC) AS customer_rank
    FROM CustomerStats cs
    WHERE cs.avg_order_value IS NOT NULL
),
SupplierRegion AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    r.r_name AS region,
    COALESCE(sr.supplier_count, 0) AS total_suppliers,
    COALESCE(tc.order_count, 0) AS total_orders,
    rp.p_name AS part_name,
    rp.p_retailprice AS part_retail_price,
    CASE 
        WHEN rp.rn = 1 THEN 'Most Expensive'
        ELSE 'Other Parts'
    END AS part_ranking
FROM region r
LEFT JOIN SupplierRegion sr ON sr.nation_name = r.r_name
LEFT JOIN TopCustomers tc ON tc.order_count > 0
JOIN RankedParts rp ON rp.rn <= 5
WHERE rp.p_size BETWEEN 10 AND 20
   OR rp.p_comment IS NULL
ORDER BY r.r_name, rp.p_retailprice DESC;
