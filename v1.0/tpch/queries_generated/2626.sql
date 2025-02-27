WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_orderkey) AS line_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.s_name, 'No Supplier') AS top_supplier,
    COALESCE(revenue.net_revenue, 0) AS total_revenue,
    ns.supplier_nation,
    customer_info.c_name,
    customer_info.c_acctbal AS customer_account_balance
FROM 
    part p
LEFT JOIN 
    HighValueParts hvp ON p.p_partkey = hvp.ps_partkey
LEFT JOIN 
    RankedSuppliers r ON r.rank = 1 AND r.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey ORDER BY ps.ps_supplycost * ps.ps_availqty DESC LIMIT 1)
LEFT JOIN 
    OrdersSummary revenue ON revenue.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = ns.supplier_nation LIMIT 1))
LEFT JOIN 
    CustomerRanked customer_info ON customer_info.rank <= 10
LEFT JOIN 
    nation ns ON ns.n_name = r.supplier_nation
WHERE 
    p.p_size > 10 AND
    (p.p_retailprice IS NOT NULL OR p.p_comment IS NOT NULL)
ORDER BY 
    total_revenue DESC, p.p_name;
