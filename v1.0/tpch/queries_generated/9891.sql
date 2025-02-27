WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate, 
        r.o_totalprice, 
        r.c_name, 
        n.n_name AS nation_name
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.OrderRank <= 5
),
ProductSales AS (
    SELECT 
        ps.ps_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_partkey
),
TopProducts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        ps.total_sales
    FROM 
        part p
    JOIN 
        ProductSales ps ON p.p_partkey = ps.ps_partkey
    ORDER BY 
        ps.total_sales DESC
    LIMIT 10
)
SELECT 
    t.o_orderkey, 
    t.o_orderdate, 
    t.o_totalprice, 
    t.c_name, 
    t.nation_name, 
    tp.p_name, 
    tp.total_sales
FROM 
    TopOrders t
JOIN 
    TopProducts tp ON t.o_orderkey = (SELECT l.l_orderkey 
                                        FROM lineitem l 
                                        WHERE l.l_partkey IN (SELECT p.p_partkey 
                                                              FROM part p 
                                                              WHERE p.p_brand = tp.p_brand)
                                        LIMIT 1)
ORDER BY 
    t.o_orderdate DESC, 
    tp.total_sales DESC;
