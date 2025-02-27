WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderAnalysis AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_count,
        MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS max_return_value,
        AVG(l.l_discount) AS avg_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
CustomerOrder AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionSupplier AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
BizarreSemantics AS (
    SELECT 
        COUNT(DISTINCT s_suppkey) AS bizarre_count,
        SUM(CASE WHEN s_acctbal IS NULL THEN 1 ELSE 0 END) AS null_balance_count
    FROM 
        supplier
    WHERE 
        s_acctbal < 0 OR s_acctbal IS NULL
)
SELECT 
    cust.c_custkey,
    cust.c_name,
    supp.total_supply_cost,
    order_analysis.line_count,
    region.supplier_count,
    region.avg_acct_balance,
    bizarre.bizarre_count,
    bizarre.null_balance_count
FROM 
    CustomerOrder cust
JOIN 
    SupplierStats supp ON cust.order_count > 0 AND supp.part_count > 10
LEFT JOIN 
    RegionSupplier region ON region.supplier_count > 5
CROSS JOIN 
    BizarreSemantics bizarre
WHERE 
    cust.total_spent > (SELECT AVG(total_spent) FROM CustomerOrder) 
    AND EXISTS (SELECT 1 FROM orders o WHERE o.o_orderkey = (cust.order_count + 100))
ORDER BY 
    cust.c_custkey ASC
LIMIT 100;
