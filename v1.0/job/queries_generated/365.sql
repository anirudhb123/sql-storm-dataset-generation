WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        md.*,
        kc.keyword_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordCounts kc ON md.movie_id = kc.movie_id
    WHERE 
        kc.keyword_count IS NOT NULL
)

SELECT 
    tm.movie_id,
    tm.title,
    COALESCE(tm.total_cast, 0) AS total_cast,
    COALESCE(tm.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN tm.total_cast > 10 THEN 'Large Cast'
        WHEN tm.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_companies mc 
     WHERE 
        mc.movie_id = tm.movie_id) AS company_count
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.keyword_count DESC
LIMIT 50;
