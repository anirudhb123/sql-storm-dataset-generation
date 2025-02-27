WITH RECURSIVE ranked_parts AS (
    SELECT 
        p_partkey,
        p_name,
        P_RETAILPRICE,
        ROW_NUMBER() OVER (PARTITION BY p_mfgr ORDER BY p_retailprice DESC) AS rank
    FROM 
        part
),
top_suppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
total_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey
),
part_seller_details AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        ts.total_avail_qty,
        COALESCE(TO_CHAR(ts.total_avail_qty), 'No Supplier') AS supplier_avail_qty,
        COUNT(DISTINCT os.o_orderkey) AS order_count,
        SUM(os.total_sales) AS total_sales
    FROM 
        ranked_parts rp
    LEFT JOIN 
        top_suppliers ts ON rp.p_partkey = ts.ps_partkey
    LEFT JOIN 
        total_orders os ON os.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = rp.p_partkey)
    WHERE 
        rp.rank <= 3
    GROUP BY 
        rp.p_partkey, rp.p_name, ts.total_avail_qty
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.total_avail_qty,
    p.supplier_avail_qty,
    p.order_count,
    p.total_sales,
    CASE 
        WHEN p.total_sales > 0 THEN 'Profitable'
        ELSE 'Not Profitable' 
    END AS profitability
FROM 
    part_seller_details p
ORDER BY 
    p.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
