WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_per_brand
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 10 AND 20
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
SupplierRegion AS (
    SELECT 
        s.s_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, r.r_name
)
SELECT 
    rp.p_name AS part_name,
    rp.p_brand AS part_brand,
    co.c_name AS customer_name,
    co.o_orderdate AS order_date,
    sr.region_name AS supplier_region,
    sr.unique_parts_supplied AS total_unique_parts,
    rp.ps_supplycost AS supply_cost,
    co.total_sales AS sales_amount
FROM RankedParts rp
JOIN CustomerOrders co ON rp.rank_per_brand <= 5
JOIN SupplierRegion sr ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = co.o_orderkey)
WHERE rp.p_brand IS NOT NULL
ORDER BY rp.p_brand, co.total_sales DESC;