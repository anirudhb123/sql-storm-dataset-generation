WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
SupplierAvailability AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
        LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'P')
        AND o.o_totalprice IS NOT NULL
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        COUNT(l.l_orderkey) > 3
),
NationSupplierCount AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
        LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
    HAVING 
        COUNT(s.s_suppkey) > 0
)
SELECT 
    DISTINCT np.n_name,
    pa.p_name,
    COALESCE(su.total_avail_qty, 0) AS total_avail_qty,
    ho.o_orderkey,
    ho.o_totalprice * (1 - AVG(l.l_discount) OVER (PARTITION BY ho.o_orderkey)) AS effective_price,
    np.supplier_count,
    CASE 
        WHEN ho.item_count > 0 THEN 'Order contains items'
        ELSE 'Order has no items'
    END AS order_item_status
FROM 
    NationSupplierCount np
    LEFT JOIN SupplierAvailability su ON np.supplier_count = su.unique_parts
    JOIN RankedParts pa ON pa.price_rank <= 10
    LEFT JOIN HighValueOrders ho ON ho.o_orderkey = su.s_suppkey
WHERE 
    pa.p_retailprice BETWEEN 100.00 AND 1000.00
ORDER BY 
    np.n_name, effective_price DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
