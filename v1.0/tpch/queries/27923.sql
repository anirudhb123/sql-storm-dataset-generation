WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone, s.s_acctbal, s.s_comment, n.n_name, r.r_name
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        LENGTH(c.c_address) AS address_length,
        SUBSTRING(c.c_phone FROM 1 FOR 3) AS area_code,
        c.c_acctbal,
        c.c_mktsegment
    FROM 
        customer c
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        DATE_PART('year', o.o_orderdate) AS order_year,
        EXTRACT(MONTH FROM o.o_orderdate) AS order_month,
        o.o_totalprice,
        o.o_clerk,
        o.o_comment,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, o.o_clerk, o.o_comment
)
SELECT 
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    cd.c_name,
    cd.address_length,
    cd.area_code,
    od.order_year,
    od.order_month,
    SUM(od.net_revenue) AS total_net_revenue,
    SUM(sd.total_supplycost) AS total_supply_cost
FROM 
    SupplierDetails sd
JOIN 
    CustomerDetails cd ON sd.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%Widget%' LIMIT 1) LIMIT 1)
JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cd.c_custkey)
GROUP BY 
    sd.s_name, sd.nation_name, sd.region_name, cd.c_name, cd.address_length, cd.area_code, od.order_year, od.order_month
ORDER BY 
    total_net_revenue DESC, sd.nation_name ASC, cd.c_name ASC
LIMIT 10;
