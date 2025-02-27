WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
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
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name AS customer_name,
        c.c_acctbal,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > 10000
)
SELECT 
    rs.s_name AS supplier_name,
    rs.supplier_nation,
    hvo.customer_name,
    hvo.o_totalprice,
    hvo.o_orderdate,
    rs.total_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    HighValueOrders hvo ON hvo.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_partkey IN (
            SELECT ps.ps_partkey
            FROM partsupp ps
            WHERE ps.ps_suppkey = rs.s_suppkey
        )
    )
WHERE 
    rs.supplier_rank <= 5
ORDER BY 
    rs.supplier_nation, rs.total_supply_cost DESC, hvo.o_totalprice DESC;
