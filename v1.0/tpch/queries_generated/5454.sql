WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CombinedSummary AS (
    SELECT 
        ss.nation,
        os.o_orderdate,
        SUM(os.total_order_value) AS total_sales,
        SUM(ss.total_supply_cost) AS total_supply_cost,
        COUNT(DISTINCT os.o_orderkey) AS order_count
    FROM 
        SupplierSummary ss
    JOIN 
        OrderSummary os ON ss.s_suppkey = (SELECT ps.ps_suppkey 
                                            FROM partsupp ps 
                                            WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                    FROM part p 
                                                                    WHERE p.p_size > 10))
    GROUP BY 
        ss.nation, os.o_orderdate
)
SELECT 
    nation,
    o_orderdate,
    total_sales,
    total_supply_cost,
    order_count,
    (total_sales - total_supply_cost) AS profit
FROM 
    CombinedSummary
ORDER BY 
    nation, o_orderdate DESC;
