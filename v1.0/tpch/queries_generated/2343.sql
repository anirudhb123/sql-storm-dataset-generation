WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS order_rank
    FROM 
        orders
    WHERE 
        o_orderdate >= DATE '2023-01-01'
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        RankedOrders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.order_rank <= 5
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) > 10000
),
FrequentSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS supply_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > (
            SELECT 
                AVG(ps_sub.ps_availqty)
            FROM 
                partsupp ps_sub
        )
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 10
),
SalesByRegion AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate >= '2023-01-01'
    GROUP BY 
        n.n_name
)
SELECT 
    h.c_name AS customer_name,
    h.total_spent AS customer_total_spent,
    f.s_name AS supplier_name,
    f.supply_count AS supplier_supply_count,
    r.nation_name,
    r.total_sales
FROM 
    HighValueCustomers h
LEFT JOIN 
    FrequentSuppliers f ON h.c_acctbal > 5000
JOIN 
    SalesByRegion r ON r.nation_name = (
        SELECT 
            n.r_name 
        FROM 
            region n 
        WHERE 
            n.r_regionkey = h.c_custkey % 5
        LIMIT 1
    )
WHERE 
    h.total_spent IS NOT NULL
ORDER BY 
    h.customer_total_spent DESC, f.supply_count ASC;
