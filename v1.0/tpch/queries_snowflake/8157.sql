WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supplier_rank <= 5
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name AS customer_name,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > 10000
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name
)
SELECT 
    tso.s_name AS supplier_name,
    tso.nation_name,
    hvo.customer_name,
    hvo.o_orderkey,
    hvo.o_totalprice,
    hvo.o_orderdate,
    hvo.lineitem_count,
    tso.total_supply_cost
FROM 
    TopSuppliers tso
JOIN 
    HighValueOrders hvo ON tso.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_orderkey = hvo.o_orderkey
    )
ORDER BY 
    tso.total_supply_cost DESC, 
    hvo.o_totalprice DESC;
