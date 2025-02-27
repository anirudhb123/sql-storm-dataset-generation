
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COALESCE(SUM(CASE WHEN mo.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS movie_note_count
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_info mo ON mo.movie_id = t.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.cast_names,
    at.kind_id,
    kt.kind AS kind_type,
    cn.name AS company_name
FROM 
    RankedMovies rm
LEFT JOIN 
    aka_title at ON at.movie_id = rm.title_id
LEFT JOIN 
    kind_type kt ON kt.id = at.kind_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = rm.title_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
