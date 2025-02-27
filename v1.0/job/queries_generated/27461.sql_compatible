
WITH MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
CastInfo AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.movie_id
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.keywords,
    mi.companies,
    COALESCE(ci.total_cast, 0) AS total_cast,
    ci.cast_names
FROM 
    MovieInfo mi
LEFT JOIN 
    CastInfo ci ON mi.movie_id = ci.movie_id
ORDER BY 
    mi.production_year DESC, 
    mi.title ASC
LIMIT 50;
