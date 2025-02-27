WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND 
        o.o_orderdate < DATE '2024-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name,
        COUNT(ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000.00
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, r.r_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000.00
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.order_rank,
    s.s_name,
    s.region_name,
    c.c_name,
    ls.total_price_after_discount AS net_total,
    ls.line_count
FROM 
    RankedOrders r
JOIN 
    LineItemSummary ls ON r.o_orderkey = ls.l_orderkey
JOIN 
    TopCustomers c ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    SupplierInfo s ON ls.total_price_after_discount IN (
        SELECT 
            SUM(l.l_extendedprice) 
        FROM 
            lineitem l 
        WHERE 
            l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
        GROUP BY l.l_orderkey
    )
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.order_rank, net_total DESC;
