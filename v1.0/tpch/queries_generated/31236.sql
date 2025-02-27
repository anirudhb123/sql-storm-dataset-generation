WITH RECURSIVE SupplyChain AS (
    SELECT 
        ps.partkey AS part_key, 
        ps.suppkey AS supp_key, 
        ps.ps_availqty AS available_quantity, 
        0 AS level
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0
    UNION ALL
    SELECT 
        ps.partkey, 
        ps.suppkey, 
        ps.ps_availqty,
        sc.level + 1
    FROM 
        partsupp ps
    JOIN 
        SupplyChain sc ON ps.partkey = sc.part_key 
    WHERE 
        sc.level < 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierRanking AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_spent, 0.00) AS total_spent,
    COALESCE(cs.avg_order_value, 0.00) AS avg_order_value,
    sr.rank AS supplier_rank,
    COALESCE(sc.available_quantity, 0) AS available_quantity,
    o.total_price,
    SUM(o.line_count) OVER (PARTITION BY c.c_custkey) AS total_lines
FROM 
    customer c
LEFT JOIN 
    CustomerStats cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    SupplierRanking sr ON sr.s_suppkey = (SELECT ps.ps_suppkey 
                                         FROM partsupp ps 
                                         WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                  FROM part p 
                                                                  WHERE p.p_size > 25)
                                         ORDER BY ps.ps_supplycost * ps.ps_availqty DESC 
                                         LIMIT 1) 
    LEFT JOIN 
        OrderSummary o ON c.c_custkey = o.o_orderkey 
LEFT JOIN 
    SupplyChain sc ON c.c_custkey = sc.supp_key 
WHERE 
    c.c_acctbal IS NOT NULL
ORDER BY 
    total_orders DESC, total_spent DESC;
