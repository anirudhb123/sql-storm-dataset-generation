WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CTE_Cust.c_name,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_status
    FROM 
        orders AS o
    JOIN 
        customer AS CTE_Cust ON o.o_custkey = CTE_Cust.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        partsupp AS ps
    GROUP BY 
        ps.ps_partkey,
        ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * sp.total_availqty) AS supplier_total_cost
    FROM 
        supplier AS s
    JOIN 
        SupplierParts AS sp ON s.s_suppkey = sp.ps_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * sp.total_availqty) < 5000
),
OrdersWithParts AS (
    SELECT 
        lo.l_orderkey,
        lo.l_partkey,
        lo.l_quantity,
        lo.l_extendedprice,
        lo.l_discount,
        RANK() OVER (PARTITION BY lo.l_orderkey ORDER BY lo.l_extendedprice DESC) AS part_rank
    FROM 
        lineitem AS lo
    WHERE 
        lo.l_shipdate >= DATE '2023-01-01' AND lo.l_shipdate < DATE '2023-12-31'
)
SELECT 
    oo.o_orderkey,
    oo.o_totalprice,
    oo.c_name,
    sp.s_name AS supplier_name,
    COUNT(op.l_partkey) AS total_parts_ordered,
    SUM(op.l_extendedprice * (1 - op.l_discount)) AS total_revenue,
    rn.r_region AS order_region,
    COALESCE(MAX(sp.supplier_total_cost), 0) AS supplier_cost
FROM 
    RankedOrders AS oo
LEFT JOIN 
    OrdersWithParts AS op ON oo.o_orderkey = op.l_orderkey
LEFT JOIN 
    TopSuppliers AS sp ON op.l_partkey IN (SELECT ps.ps_partkey FROM partsupp AS ps WHERE ps.ps_suppkey = sp.s_suppkey)
LEFT JOIN 
    nation AS n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer AS c WHERE c.c_custkey = oo.o_custkey)
LEFT JOIN 
    region AS rn ON n.n_regionkey = rn.r_regionkey
WHERE 
    oo.rank_status <= 5
GROUP BY 
    oo.o_orderkey, oo.o_totalprice, oo.c_name, sp.s_name, rn.r_region
HAVING 
    SUM(op.l_extendedprice * (1 - op.l_discount)) > 1000
ORDER BY 
    oo.o_orderdate DESC, total_revenue DESC;
