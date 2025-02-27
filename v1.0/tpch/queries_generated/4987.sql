WITH SupplierCosts AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
)
SELECT 
    pd.p_brand,
    SUM(pd.p_retailprice * (COALESCE(ol.line_count, 0))) AS total_value,
    AVG(cc.order_count) AS avg_orders_per_customer,
    MAX(sc.total_supply_cost) AS max_supply_cost
FROM 
    PartDetails pd
LEFT JOIN (
    SELECT 
        l.l_partkey,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
) ol ON pd.p_partkey = ol.l_partkey
LEFT JOIN 
    CustomerOrderCounts cc ON pd.supplier_count = cc.order_count
JOIN 
    SupplierCosts sc ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sc.ps_suppkey)
WHERE 
    pd.p_retailprice > (
        SELECT 
            AVG(p2.p_retailprice)
        FROM 
            part p2
    )
GROUP BY 
    pd.p_brand
ORDER BY 
    total_value DESC;
