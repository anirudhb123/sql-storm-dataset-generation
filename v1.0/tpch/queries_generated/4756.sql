WITH OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND 
        o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey, 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
)
SELECT 
    sub.region_name,
    sub.total_revenue,
    sub.unique_parts,
    COALESCE(sup.total_supply_cost, 0) AS total_supply_cost
FROM 
    (
        SELECT 
            n.n_name AS region_name,
            SUM(os.total_revenue) AS total_revenue,
            SUM(os.unique_parts) AS unique_parts
        FROM 
            nation n
        LEFT JOIN 
            (SELECT DISTINCT o.o_custkey, os.total_revenue, os.unique_parts 
             FROM OrderSummary os 
             JOIN customer c ON os.o_orderkey = (SELECT o.o_orderkey 
                                                  FROM orders o 
                                                  WHERE o.o_custkey = c.c_custkey 
                                                  LIMIT 1) 
             GROUP BY c.c_custkey, os.total_revenue, os.unique_parts) os ON c.c_custkey = os.o_custkey
        GROUP BY 
            n.n_name
    ) sub
LEFT JOIN 
    SupplierInfo sup ON sub.unique_parts > 0
ORDER BY 
    sub.total_revenue DESC, 
    sub.unique_parts ASC;
