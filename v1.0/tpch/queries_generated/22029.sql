WITH SupplierAggregate AS (
    SELECT 
        s_nationkey,
        SUM(s_acctbal) AS total_acctbal,
        COUNT(DISTINCT s_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY SUM(s_acctbal) DESC) AS rank
    FROM supplier
    GROUP BY s_nationkey
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice > 1000 THEN 'High'
            WHEN p.p_retailprice BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS price_category
    FROM part p
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('F', 'P')
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name,
    COALESCE(sa.supplier_count, 0) AS supplier_count,
    p.price_category,
    SUM(p.p_retailprice * ls.l_quantity) AS total_revenue,
    AVG(ls.l_discount) AS average_discount,
    STRING_AGG(DISTINCT n.n_name, ', ') FILTER (WHERE n.n_name IS NOT NULL) AS supplier_nations,
    CASE 
        WHEN p.p_retailprice IS NOT NULL AND sa.supplier_count IS NULL THEN 'orphan_part'
        ELSE 'regular_part'
    END AS part_status
FROM 
    HighValueParts p
LEFT JOIN 
    PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierAggregate sa ON ps.ps_suppkey = sa.s_nationkey
LEFT JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
LEFT JOIN 
    nation n ON n.n_nationkey = sa.s_nationkey
GROUP BY 
    p.p_name, p.price_category, sa.supplier_count
HAVING 
    COUNT(DISTINCT ls.l_orderkey) > 0
ORDER BY 
    total_revenue DESC 
LIMIT 100;
