SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue

