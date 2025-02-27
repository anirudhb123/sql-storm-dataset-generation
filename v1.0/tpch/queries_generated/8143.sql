WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_avail_qty,
        rs.total_supply_cost,
        n.n_name AS nation_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.nation_name,
    COUNT(os.o_orderkey) AS order_count,
    SUM(os.total_order_value) AS total_order_value,
    SUM(ts.total_avail_qty) AS total_available_quantity,
    SUM(ts.total_supply_cost) AS total_supplier_cost
FROM 
    TopSuppliers ts
JOIN 
    OrderSummary os ON ts.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            JOIN orders o ON l.l_orderkey = o.o_orderkey 
            WHERE o.o_orderdate > '2021-01-01'
        )
    )
GROUP BY 
    ts.nation_name
ORDER BY 
    total_order_value DESC, order_count DESC;
