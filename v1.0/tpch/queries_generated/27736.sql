WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT p.p_brand, ', ') AS brands_supplied,
        STRING_AGG(DISTINCT p.p_type, ', ') AS types_supplied
    FROM 
        supplier s
        JOIN nation n ON s.s_nationkey = n.n_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        STRING_AGG(DISTINCT o.o_orderpriority, ', ') AS order_priorities
    FROM 
        customer c
        JOIN nation n ON c.c_nationkey = n.n_nationkey
        JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
)
SELECT 
    sd.s_name AS supplier_name,
    cd.c_name AS customer_name,
    sd.part_count,
    cd.order_count,
    sd.total_supply_cost,
    cd.total_spent,
    sd.brands_supplied,
    cd.order_priorities
FROM 
    SupplierDetails sd
    JOIN CustomerDetails cd ON sd.nation_name = cd.nation_name
WHERE 
    sd.total_supply_cost > 10000 AND cd.total_spent < 5000
ORDER BY 
    sd.total_supply_cost DESC, cd.total_spent ASC;
