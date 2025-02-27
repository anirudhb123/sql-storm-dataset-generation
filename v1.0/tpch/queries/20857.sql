
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment, 
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_mktsegment
    FROM 
        RankedOrders r
    WHERE 
        r.price_rank = 1
), SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(s.s_comment, 'No comment') AS adjusted_comment
    FROM 
        supplier s
    JOIN 
        SupplierInfo si ON s.s_suppkey = si.ps_suppkey
    WHERE 
        si.supply_rank <= 5
), OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    JOIN 
        HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
    GROUP BY 
        l.l_orderkey
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    hvo.c_mktsegment,
    COALESCE(od.net_value, 0) AS order_net_value,
    COALESCE(od.line_count, 0) AS item_count,
    s.s_name,
    s.adjusted_comment
FROM 
    HighValueOrders hvo
LEFT JOIN 
    OrderDetails od ON hvo.o_orderkey = od.l_orderkey
LEFT JOIN 
    FilteredSuppliers s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_orderkey = hvo.o_orderkey
    )
WHERE 
    hvo.o_totalprice > (
        SELECT AVG(o.o_totalprice) 
        FROM orders o 
        WHERE o.o_orderstatus = 'O'
    )
ORDER BY 
    hvo.o_orderdate DESC, 
    hvo.o_orderkey ASC;
