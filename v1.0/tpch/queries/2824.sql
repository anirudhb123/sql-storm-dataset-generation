WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON l.l_partkey = ps.ps_partkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS average_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000.00
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) >= 5
),
FilterNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name
    FROM 
        nation n
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey 
                           FROM region r 
                           WHERE r.r_name LIKE 'Asia%')
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(s.total_sales, 0) AS supplier_sales,
    c.order_count,
    c.average_order_value,
    n.n_name AS nation_name
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierSales s ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                        FROM partsupp ps 
                                        JOIN lineitem l ON l.l_partkey = ps.ps_partkey 
                                        WHERE l.l_orderkey = r.o_orderkey 
                                        LIMIT 1)
LEFT JOIN 
    CustomerOrders c ON c.c_custkey = (SELECT o.o_custkey 
                                         FROM orders o 
                                         WHERE o.o_orderkey = r.o_orderkey 
                                         LIMIT 1)
LEFT JOIN 
    FilterNation n ON n.n_nationkey = (SELECT c.c_nationkey 
                                         FROM customer c 
                                         WHERE c.c_custkey = c.c_custkey 
                                         LIMIT 1)
WHERE 
    r.order_rank <= 100;