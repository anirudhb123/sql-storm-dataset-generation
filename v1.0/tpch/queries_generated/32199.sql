WITH RECURSIVE SupplyChain AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rank
    FROM 
        partsupp
    WHERE 
        ps_availqty > 100
    UNION ALL
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        p.ps_availqty,
        p.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.ps_supplycost DESC)
    FROM 
        partsupp p
    JOIN 
        SupplyChain sc ON p.ps_partkey = sc.ps_partkey
    WHERE 
        p.ps_supplycost < sc.ps_supplycost
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PriceAggregate AS (
    SELECT 
        p.p_partkey,
        MAX(p.p_retailprice) AS max_price,
        MIN(p.p_retailprice) AS min_price,
        COUNT(ps.ps_supplycost) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT
    n.n_name,
    COUNT(DISTINCT sc.ps_suppkey) AS unique_suppliers,
    AVG(co.total_spent) AS avg_customer_spent,
    SUM(pa.max_price) AS total_max_prices,
    SUM(pa.min_price) AS total_min_prices,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplyChain sc ON s.s_suppkey = sc.ps_suppkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = s.s_suppkey
LEFT JOIN 
    PriceAggregate pa ON pa.p_partkey = sc.ps_partkey
WHERE 
    n.n_name IS NOT NULL
    AND (co.order_count > 5 OR pa.supplier_count > 10)
GROUP BY 
    n.n_name
ORDER BY 
    avg_customer_spent DESC;
