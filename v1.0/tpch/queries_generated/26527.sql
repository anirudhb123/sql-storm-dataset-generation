WITH PartDetails AS (
    SELECT 
        p.p_name AS part_name,
        p.p_brand AS brand,
        p.p_type AS type,
        p.p_size AS size,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        p.p_comment AS part_comment,
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), CustomerOrderDetails AS (
    SELECT 
        c.c_name AS customer_name,
        c.c_address AS customer_address,
        o.o_orderkey AS order_key,
        o.o_orderdate AS order_date,
        o.o_totalprice AS total_price,
        o.o_comment AS order_comment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
), BenchmarkResults AS (
    SELECT 
        pd.part_name,
        pd.brand,
        pd.type,
        pd.size,
        pd.available_quantity,
        pd.supply_cost,
        pd.part_comment,
        cod.customer_name,
        cod.customer_address,
        cod.order_key,
        cod.order_date,
        cod.total_price,
        cod.order_comment,
        CONCAT(pd.brand, ' - ', pd.part_name, ' available in ', pd.size, ' size, from supplier ', pd.supplier_name, ' located at ', pd.supplier_address, ' in the region of ', pd.region_name, ' for customer ', cod.customer_name, ' residing at ', cod.customer_address, ' with order key ', cod.order_key, ' on date ', cod.order_date) AS benchmark_string
    FROM 
        PartDetails pd
    JOIN 
        CustomerOrderDetails cod ON pd.available_quantity > 0
)
SELECT 
    benchmark_string
FROM 
    BenchmarkResults
WHERE 
    LENGTH(benchmark_string) > 1000
ORDER BY 
    total_price DESC
LIMIT 10;
