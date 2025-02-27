WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS supply_count
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
        AND p.p_size IS NOT NULL
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    INNER JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        CASE 
            WHEN ps.ps_supplycost IS NULL THEN 'UNKNOWN'
            ELSE TO_CHAR(ps.ps_supplycost, 'FM999999999999.00')
        END AS formatted_supplycost,
        COALESCE(p.p_name, 'NO PART') AS associated_part
    FROM 
        partsupp ps
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    c.c_name AS customer_name,
    pp.p_name AS most_expensive_part,
    pp.p_brand,
    pp.p_retailprice,
    psd.formatted_supplycost,
    psd.ps_availqty, 
    tc.total_spent,
    CASE 
        WHEN tc.total_spent > 1000 THEN 'High Roller'
        ELSE 'Casual Spender'
    END AS customer_type,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY pp.p_retailprice DESC) AS part_rank
FROM 
    TopCustomers tc
JOIN 
    RankedParts pp ON tc.total_spent > 500 AND pp.price_rank <= 3
LEFT JOIN 
    PartSupplierDetails psd ON pp.p_partkey = psd.ps_partkey
WHERE 
    pp.p_brand IN (SELECT DISTINCT p_brand FROM part WHERE p_size < 10)
    OR pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 100)
ORDER BY 
    customer_name, most_expensive_part DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
