WITH SupplyCostSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, c.c_custkey
),
FinalReport AS (
    SELECT 
        s.s_name,
        s.nation_name,
        ss.p_name,
        ss.total_supply_cost,
        os.total_order_value
    FROM 
        TopSuppliers s
    JOIN 
        SupplyCostSummary ss ON ss.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey LIMIT 1)
    JOIN 
        OrderSummary os ON os.c_custkey = (SELECT c.c_custkey FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey WHERE o.o_orderkey = (SELECT MIN(o_orderkey) FROM orders) LIMIT 1)
    WHERE 
        ss.total_supply_cost > 1000
)

SELECT * FROM FinalReport
ORDER BY total_supply_cost DESC, total_order_value DESC;
