WITH RECURSIVE Order_Summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderstatus IN ('O', 'F')

    UNION ALL

    SELECT 
        os.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        os.level + 1
    FROM 
        Order_Summary os
    JOIN 
        orders o ON o.o_orderkey = os.o_orderkey 
    WHERE 
        os.level < 5
),

Average_Price AS (
    SELECT 
        l.l_partkey,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01'
    GROUP BY 
        l.l_partkey
),

Supplier_Stats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        total_supplycost > 10000
),

Customer_Sales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        total_spent > 50000
)

SELECT 
    c.c_name, 
    o.o_orderdate,
    os.o_orderstatus,
    AVG(ap.avg_price) AS average_lineitem_price,
    ss.parts_supplied AS supplier_part_count
FROM 
    Customer_Sales c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    Order_Summary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN 
    Average_Price ap ON os.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey)
LEFT JOIN 
    Supplier_Stats ss ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps 
                                            JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                            WHERE l.l_orderkey = os.o_orderkey LIMIT 1)
GROUP BY 
    c.c_name, o.o_orderdate, os.o_orderstatus, ss.parts_supplied
ORDER BY 
    average_lineitem_price DESC, c.c_name ASC
LIMIT 100;
