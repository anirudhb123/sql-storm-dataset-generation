WITH NationalSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
),
TopNations AS (
    SELECT 
        nation_name,
        total_supply_cost,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS rank
    FROM 
        NationalSuppliers
)
SELECT 
    cn.c_name AS customer_name,
    co.o_orderkey AS order_id,
    li.l_quantity AS line_quantity,
    li.l_extendedprice AS extended_price,
    tn.nation_name AS supplier_nation,
    tn.total_supply_cost
FROM 
    customer cn
JOIN 
    orders co ON cn.c_custkey = co.o_custkey
JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    TopNations tn ON s.s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = tn.nation_name)
WHERE 
    co.o_orderdate >= '1997-01-01' 
    AND co.o_orderdate < '1998-01-01' 
    AND tn.rank <= 5
ORDER BY 
    tn.total_supply_cost DESC, cn.c_name;