WITH RecursiveSupplier AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey, 
        s.s_acctbal,
        1 AS depth
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL
    
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey, 
        s.s_acctbal,
        rs.depth + 1
    FROM 
        supplier s
    JOIN RecursiveSupplier rs ON s.s_nationkey = rs.s_nationkey
    WHERE 
        s.s_acctbal > rs.s_acctbal
),

LineItemWithDiscount AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_discount,
        l.l_extendedprice,
        CASE 
            WHEN l.l_discount = 0 THEN 'No Discount'
            WHEN l.l_discount BETWEEN 0.01 AND 0.1 THEN 'Low Discount'
            ELSE 'High Discount'
        END AS discount_status
    FROM 
        lineitem l
),

FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        LineItemWithDiscount li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND 
        o.o_orderdate < DATE '2023-01-01' AND 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
    HAVING 
        total_revenue > (SELECT AVG(SUM(l.l_extendedprice * (1 - l.l_discount))) 
                          FROM lineitem l 
                          JOIN orders oo ON l.l_orderkey = oo.o_orderkey 
                          WHERE oo.o_orderstatus = 'F')
),

CustomerCountry AS (
    SELECT 
        c.c_custkey,
        c.c_name, 
        n.n_name AS nation_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
)

SELECT 
    r.supp_key, 
    r.s_name AS supplier_name, 
    r.nation_name, 
    COALESCE(c.total_spent, 0) AS customer_total_spent, 
    coalesce(o.line_item_count, 0) as total_orders,
    CASE 
        WHEN o.total_revenue IS NULL THEN 'No Order'
        ELSE 'Order Present'
    END AS order_status
FROM 
    RecursiveSupplier r
LEFT JOIN 
    FilteredOrders o ON r.s_suppkey = o.o_orderkey
LEFT JOIN 
    CustomerCountry c ON c.order_count > (SELECT COUNT(*) FROM customer) / 10
WHERE 
    r.depth <= 3
ORDER BY 
    r.s_name ASC,
    r.s_suppkey DESC;
