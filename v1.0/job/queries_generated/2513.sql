WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN ci.kind = 'Director' THEN 1 ELSE 0 END) OVER (PARTITION BY t.id) AS avg_directors,
        SUM(CASE WHEN k.keyword IN ('Action', 'Drama') THEN 1 ELSE 0 END) AS genre_count
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        info_type it ON cc.status_id = it.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS movie_rank
    FROM 
        RankedMovies
    WHERE 
        genre_count > 0
)
SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    f.avg_directors
FROM 
    FilteredMovies f
WHERE 
    f.movie_rank <= 10
ORDER BY 
    f.production_year DESC, f.cast_count DESC
UNION ALL
SELECT 
    'Average' AS title,
    NULL AS production_year,
    AVG(cast_count) AS cast_count,
    AVG(avg_directors) AS avg_directors
FROM 
    FilteredMovies;
