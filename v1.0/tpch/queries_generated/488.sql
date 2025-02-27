WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) as account_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        c.c_name, 
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
    GROUP BY 
        o.o_orderkey, o.o_totalprice, c.c_name
), 
AggregateLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate <= '2023-12-31'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    h.o_orderkey,
    h.o_totalprice,
    h.c_name,
    COALESCE(a.total_value, 0) AS total_lineitem_value,
    s.s_name AS top_supplier,
    s.s_acctbal AS top_supplier_acctbal
FROM 
    HighValueOrders h
LEFT JOIN 
    AggregateLineItems a ON h.o_orderkey = a.l_orderkey
LEFT JOIN 
    RankedSuppliers s ON s.account_rank = 1
WHERE 
    h.lineitem_count > 5
ORDER BY 
    h.o_totalprice DESC, 
    h.c_name;
