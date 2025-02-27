WITH TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1994-01-01'
        AND l.l_shipdate < DATE '1995-01-01'
    GROUP BY 
        l.l_orderkey
),
RankedSales AS (
    SELECT 
        ts.l_orderkey,
        ts.sales,
        RANK() OVER (ORDER BY ts.sales DESC) AS sales_rank
    FROM 
        TotalSales ts
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        R.cust_name,
        R.n_name AS nation_name,
        R.supp_name
    FROM 
        orders o
    JOIN 
        RankedSales rs ON o.o_orderkey = rs.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation R ON c.c_nationkey = R.n_nationkey
    WHERE 
        rs.sales_rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    COALESCE(co.o_orderkey, 0) AS order_key,
    COALESCE(co.o_orderstatus, 'N/A') AS order_status,
    COALESCE(co.o_totalprice, 0.00) AS total_price,
    COALESCE(co.cust_name, 'Unknown') AS customer_name,
    COALESCE(co.nation_name, 'Unknown') AS customer_nation,
    COALESCE(sd.s_name, 'Unknown') AS supplier_name,
    COALESCE(sd.s_acctbal, 0.00) AS supplier_balance,
    COALESCE(sd.nation, 'Unknown') AS supplier_nation
FROM 
    CustomerOrders co
FULL OUTER JOIN 
    SupplierDetails sd ON co.o_orderkey = sd.ps_suppkey
ORDER BY 
    co.o_orderkey, sd.s_name;
