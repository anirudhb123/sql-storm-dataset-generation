WITH movie_info_aggregated AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS collective_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info LIKE '%Award%' OR it.info LIKE '%Nomination%'
    GROUP BY 
        mi.movie_id
),
cast_aggregated AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        ci.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    t.title,
    t.production_year,
    ma.collective_info AS movie_awards,
    ca.total_cast,
    ca.cast_names,
    co.production_companies
FROM 
    title t
LEFT JOIN 
    movie_info_aggregated ma ON t.id = ma.movie_id
LEFT JOIN 
    cast_aggregated ca ON t.id = ca.movie_id
LEFT JOIN 
    company_info co ON t.id = co.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
