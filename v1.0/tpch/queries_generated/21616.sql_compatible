
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p1.p_retailprice) FROM part p1)
),
CustomerPayments AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice - l.l_discount * o.o_totalprice) AS total_payment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1998-10-01'
    GROUP BY 
        c.c_custkey
),
SupplierAvailability AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS available_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty IS NOT NULL
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    SUM(COALESCE(cp.total_payment, 0)) AS total_customer_payments,
    SUM(COALESCE(p.p_retailprice, 0)) AS total_part_retail_price,
    AVG(sa.available_parts) AS average_available_parts,
    STRING_AGG(DISTINCT p.p_name, ', ') AS top_parts
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    CustomerPayments cp ON cp.c_custkey = ns.n_nationkey
LEFT JOIN 
    RankedParts p ON p.price_rank <= 5
LEFT JOIN 
    SupplierAvailability sa ON sa.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
WHERE 
    ns.n_nationkey IN (SELECT DISTINCT c.c_nationkey FROM customer c)
GROUP BY 
    r.r_name, ns.n_name
HAVING 
    SUM(COALESCE(cp.total_payment, 0)) > 10000
    AND COUNT(DISTINCT p.p_partkey) > 0
ORDER BY 
    total_customer_payments DESC, average_available_parts ASC;
