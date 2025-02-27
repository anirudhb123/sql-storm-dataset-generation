WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        k.keyword, 
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
RankedMovies AS (
    SELECT 
        md.*, 
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    rm.keyword, 
    rm.cast_count
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC
UNION ALL
SELECT 
    NULL AS movie_id, 
    'Total Movies' AS title, 
    NULL AS production_year, 
    NULL AS keyword, 
    COUNT(*) AS cast_count
FROM 
    cast_info
WHERE 
    person_id IS NOT NULL
ORDER BY 
    production_year, title;
