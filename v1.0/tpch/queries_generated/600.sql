WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS mkt_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
SupplierPartAvailability AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS available_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    r.r_name AS region,
    NVL(SUM(p.ps_availqty), 0) AS total_part_avail_qty,
    SUM(CASE WHEN hvc.mkt_rank <= 10 THEN hvc.c_acctbal ELSE 0 END) AS top_customer_acct_balance_sum,
    AVG(s.p_part_avg_price) AS avg_part_price_per_supplier,
    COALESCE(supplier_availability.available_parts, 0) AS supplier_available_parts
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    RankedOrders ro ON c.c_custkey = ro.c_custkey
LEFT JOIN 
    HighValueCustomers hvc ON c.c_custkey = hvc.c_custkey
LEFT JOIN 
    (SELECT 
        ps.ps_partkey, 
        AVG(p.p_retailprice) AS p_part_avg_price 
     FROM 
        partsupp ps 
     JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
     GROUP BY 
        ps.ps_partkey
    ) s ON ro.o_orderkey = s.o_orderkey
LEFT JOIN 
    SupplierPartAvailability supplier_availability ON s.s_name = supplier_availability.s_name
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_part_avail_qty DESC, 
    region;
