WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
DailyOrderTotals AS (
    SELECT 
        o.o_orderdate,
        SUM(o.o_totalprice) AS total_daily_sales,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        orders o
    GROUP BY 
        o.o_orderdate
), 
CustomerSummary AS (
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
)

SELECT 
    r.r_name,
    CONCAT(c.c_name, ' - ', COALESCE(ct.total_spent, 0)) AS customer_info,
    pp.p_name,
    pp.p_retailprice,
    ds.total_daily_sales,
    ss.total_supply_cost,
    CASE 
        WHEN pp.price_rank = 1 THEN 'Most Expensive'
        ELSE 'Other'
    END AS price_category
FROM 
    RankedParts pp
JOIN 
    SupplierStats ss ON pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp))
LEFT JOIN 
    CustomerSummary ct ON ct.total_spent IS NOT NULL AND ct.total_spent < (
        SELECT AVG(total_spent) * 1.5 FROM CustomerSummary
    )
JOIN 
    region r ON (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey IN (SELECT c.c_nationkey FROM customer c)) = r.r_regionkey
LEFT JOIN 
    DailyOrderTotals ds ON ds.o_orderdate = CURRENT_DATE
WHERE 
    pp.p_retailprice BETWEEN 10.00 AND 1000.00
ORDER BY 
    r.r_name, pp.p_retailprice DESC;
