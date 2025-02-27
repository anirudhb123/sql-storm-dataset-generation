
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year 
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id, 
        tm.title, 
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent' 
    END AS era
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordCount kc ON md.movie_id = kc.movie_id
WHERE 
    md.production_year IS NOT NULL 
ORDER BY 
    md.production_year DESC, 
    keyword_count DESC;
