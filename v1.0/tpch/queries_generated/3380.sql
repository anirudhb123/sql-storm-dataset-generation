WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
AggLineItem AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_profit,
        COUNT(*) AS line_item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' 
        AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_name,
    p.p_size,
    p.p_mfgr,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    COALESCE(c.total_spent, 0) AS total_spent_by_customer,
    al.total_line_profit,
    al.line_item_count,
    r.r_name
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank <= 3
LEFT JOIN 
    CustomerOrders c ON ps.ps_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = s.s_suppkey LIMIT 1)
LEFT JOIN 
    AggLineItem al ON al.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey LIMIT 1)
JOIN 
    nation n ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = ps.ps_suppkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size = p.p_size)
ORDER BY 
    total_line_profit DESC, 
    supplier_name ASC;
