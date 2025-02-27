WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) as title_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
),
movie_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COUNT(DISTINCT c.person_id) AS cast_member_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        ranked_movies rm ON c.movie_id = rm.movie_id
    GROUP BY 
        c.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    mc.cast_names,
    mc.cast_member_count,
    ci.companies,
    ci.company_types
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_cast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_info ci ON rm.movie_id = ci.movie_id
ORDER BY 
    rm.production_year, rm.title;
