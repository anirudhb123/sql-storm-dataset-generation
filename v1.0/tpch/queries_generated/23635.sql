WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price,
        COUNT(DISTINCT ps.s_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
TopParts AS (
    SELECT *
    FROM RankedParts
    WHERE rank_price <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        c.c_mktsegment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    cp.c_custkey, 
    cp.c_name, 
    cp.total_spent,
    tp.p_name,
    tp.rank_price,
    CASE 
        WHEN cp.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Active Purchaser'
    END AS purchase_status
FROM 
    CustomerOrders cp
FULL OUTER JOIN 
    TopParts tp ON cp.c_mktsegment = 'FURNISHINGS'
WHERE 
    (cp.total_spent IS NOT NULL OR tp.p_retailprice > 100.00)
    AND (tp.p_size IS NULL OR tp.supplier_count > 2)
ORDER BY 
    cp.total_spent DESC NULLS LAST,
    tp.rank_price ASC
FETCH FIRST 10 ROWS ONLY;
