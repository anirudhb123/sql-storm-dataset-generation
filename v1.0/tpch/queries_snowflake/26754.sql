
WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 50.00)
),
ProductSuppliers AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        s.s_acctbal AS supplier_balance,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost
    FROM 
        RankedProducts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        rp.price_rank <= 5
)
SELECT 
    p.p_brand,
    COUNT(*) AS supplier_count,
    AVG(ps.supply_cost) AS avg_supply_cost,
    SUM(ps.available_quantity) AS total_available_quantity,
    LISTAGG(DISTINCT ps.supplier_name, ', ') AS supplier_names
FROM 
    ProductSuppliers ps
JOIN 
    RankedProducts p ON ps.p_partkey = p.p_partkey
GROUP BY 
    p.p_brand
ORDER BY 
    supplier_count DESC;
