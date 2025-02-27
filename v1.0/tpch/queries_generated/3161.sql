WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(s.s_acctbal) AS avg_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
DateFilteredLineItems AS (
    SELECT 
        l.orderkey,
        l.partkey,
        l.suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_returnflag,
        l.l_linestatus,
        DATEDIFF(day, l.l_shipdate, GETDATE()) AS days_since_ship
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < DATEADD(day, -30, GETDATE()) -- items shipped more than 30 days ago
)
SELECT 
    r.r_name AS region_name,
    SUM(CASE WHEN c.total_spent > 1000 THEN 1 ELSE 0 END) AS high_spending_customers,
    COUNT(DISTINCT d.orderkey) AS old_lineitem_count,
    SUM(p.p_retailprice) AS total_retail_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    RankedParts p ON ps.ps_partkey = p.p_partkey AND p.rn = 1 -- Get highest priced part for the type
LEFT JOIN 
    CustomerOrders c ON s.s_suppkey = c.c_custkey
LEFT JOIN 
    DateFilteredLineItems d ON d.partkey = p.p_partkey
GROUP BY 
    r.r_name
ORDER BY 
    region_name;
