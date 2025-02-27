WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_price,
        COUNT(*) OVER (PARTITION BY p.p_type) AS count_per_type
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = p.p_type)
), CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)

SELECT 
    p.p_name,
    c.c_name,
    COALESCE(sd.s_name, 'No Supplier') AS supplier_name,
    p.p_retailprice,
    cs.total_spent AS customer_spending,
    ps.total_available AS supplier_availability,
    CASE 
        WHEN p.rank_price <= 5 THEN 'Top 5 by Price'
        WHEN p.count_per_type > 10 THEN 'Popular Type'
        ELSE 'Other'
    END AS classification
FROM 
    RankedParts p
LEFT JOIN 
    CustomerStats cs ON cs.order_count > 2
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey AND l.l_quantity > 0
LEFT JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE 
    p.p_size IS NOT NULL
AND 
    (COALESCE(cs.total_spent, 0) > 1000 OR sd.total_available IS NULL)
AND 
    p.p_retailprice < (SELECT MAX(p2.p_retailprice) FROM part p2 WHERE p2.p_size BETWEEN 10 AND 20)
ORDER BY 
    classification, customer_spending DESC;
