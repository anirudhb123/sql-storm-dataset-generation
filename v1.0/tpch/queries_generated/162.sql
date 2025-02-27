WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey
),
PartPriceAnalysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_size > 30 THEN p.p_retailprice * 0.9
            ELSE p.p_retailprice
        END AS adjusted_price
    FROM 
        part p
)
SELECT 
    r.r_name,
    SUM(COALESCE(orders_total, 0)) AS total_order_value_per_region,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(adjusted_price) AS avg_adjusted_price
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    PartPriceAnalysis ppa ON l.l_partkey = ppa.p_partkey
LEFT JOIN 
    (SELECT 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS orders_total
     FROM 
        partsupp ps
     JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
     GROUP BY 
        s.s_nationkey) supp_totals ON supp_totals.s_nationkey = n.n_nationkey
GROUP BY 
    r.r_name
ORDER BY 
    total_order_value_per_region DESC;
