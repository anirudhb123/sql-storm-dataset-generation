WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.total_revenue,
        o.item_count
    FROM 
        customer c
    LEFT JOIN 
        OrderSummary o ON c.c_custkey = o.o_custkey
    WHERE 
        o.order_rank = 1 OR o.order_rank IS NULL
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(MAX(s.total_supply_cost), 0) AS max_supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierInfo s ON EXISTS (
            SELECT 1 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey 
            AND ps.ps_suppkey = s.s_suppkey
        )
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
)
SELECT 
    c.c_name AS customer_name,
    p.p_name AS part_name,
    p.p_brand AS brand,
    p.p_retailprice AS retail_price,
    COALESCE(td.max_supply_cost, 0) AS max_supply_cost,
    c.c_acctbal - IFNULL(td.max_supply_cost, 0) AS balance_after_cost
FROM 
    TopCustomers c
FULL OUTER JOIN 
    PartDetails p ON c.total_revenue > 1000 OR p.p_retailprice IS NULL
WHERE 
    c.c_acctbal IS NOT NULL AND p.p_retailprice < 50
ORDER BY 
    c.c_name, p.p_brand;
