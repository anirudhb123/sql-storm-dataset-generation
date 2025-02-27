WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_items_price,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
TopSuppliers AS (
    SELECT 
        s.* 
    FROM 
        SupplierDetails s
    WHERE 
        s.total_supply_value >= (
            SELECT 
                AVG(total_supply_value) 
            FROM 
                SupplierDetails
        )
)
SELECT 
    t.nation_name, 
    t.s_name, 
    t.s_acctbal,
    o.o_orderkey, 
    o.total_line_items_price 
FROM 
    TopSuppliers t
LEFT JOIN 
    OrderSummary o ON t.s_suppkey = (
        SELECT 
            l.l_suppkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_orderkey = o.o_orderkey 
        LIMIT 1
    )
ORDER BY 
    nation_name, 
    s_acctbal DESC;
