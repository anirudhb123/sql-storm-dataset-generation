WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        p.p_retailprice > 100 AND total_availqty > 0
),
CustomerSpending AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        total_spent > 500 AND last_order_date < CURRENT_DATE - INTERVAL '1 year'
),
SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        supplied_parts > 5
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(ROUND(AVG(hp.p_retailprice), 2), 0) AS avg_high_value_part_price,
    COALESCE(SUM(CASE WHEN r.order_rank <= 10 THEN r.o_totalprice ELSE 0 END), 0) AS total_top_orders,
    s.supplied_parts
FROM 
    CustomerSpending c
LEFT JOIN 
    RankedOrders r ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    HighValueParts hp ON EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_partkey = hp.p_partkey AND ps.ps_availqty > 0)
LEFT JOIN 
    SupplierParts s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100))
GROUP BY 
    c.c_custkey, c.c_name, s.supplied_parts
HAVING 
    avg_high_value_part_price IS NOT NULL OR total_top_orders > 1000;
