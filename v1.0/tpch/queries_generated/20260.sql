WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
TotalPricePerCustomer AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 0
),
FinalResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        AVG(o.o_totalprice) AS avg_order_value,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold,
        COALESCE(a.total_available, 0) AS total_available_stock
    FROM 
        RankedParts p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN 
        SupplierAvailability a ON p.p_partkey = a.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.p_brand,
    f.avg_order_value,
    f.total_quantity_sold,
    f.total_available_stock,
    CASE 
        WHEN f.avg_order_value IS NULL THEN 'No Sales'
        WHEN f.total_quantity_sold >= 100 THEN 'High Demand'
        ELSE 'Low Demand'
    END AS demand_status,
    RANK() OVER (ORDER BY f.total_quantity_sold DESC) AS demand_rank
FROM 
    FinalResults f
WHERE 
    f.total_available_stock > (SELECT AVG(total_available_stock) FROM FinalResults) 
    AND f.p_partkey IN (SELECT p.p_partkey FROM RankedParts p WHERE p.rn <= 3)
ORDER BY 
    f.demand_rank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
