WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    INNER JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    INNER JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
)
SELECT 
    COALESCE(cp.c_name, 'No Customers') AS Customer_Name,
    rp.p_name AS Top_Priced_Part,
    si.region_name AS Supplier_Region,
    si.part_count AS Supplier_Part_Count
FROM 
    RankedParts rp
FULL OUTER JOIN 
    CustomerOrders cp ON cp.custkey = (SELECT c.c_custkey FROM customer c ORDER BY RANDOM() LIMIT 1)
LEFT JOIN 
    SupplierInfo si ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty < 10 ORDER BY RANDOM() LIMIT 1)
WHERE 
    rp.price_rank = 1 OR si.part_count IS NULL
ORDER BY 
    cp.total_spent DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
