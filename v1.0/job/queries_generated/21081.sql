WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        rn.rank AS title_rank,
        COALESCE(SUM(mk.keyword_count), 0) AS keyword_count,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(*) AS keyword_count 
        FROM 
            movie_keyword 
        GROUP BY movie_id
    ) mk ON t.movie_id = mk.movie_id
    LEFT JOIN cast_info ci ON t.movie_id = ci.movie_id
    JOIN (
        SELECT 
            movie_id, 
            ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
        FROM 
            aka_title t
        JOIN cast_info ci ON t.movie_id = ci.movie_id
        GROUP BY movie_id, production_year
    ) rn ON rn.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, rn.rank
    HAVING 
        COALESCE(SUM(mk.keyword_count), 0) > 2
),

EarlyDirectors AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS director_count
    FROM 
        cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role = 'Director'
        AND ci.nr_order = 1
    GROUP BY 
        ci.movie_id
),

MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.title_rank,
        rm.keyword_count,
        ed.director_count,
        CASE 
            WHEN rm.cast_count > 10 THEN 'Large Cast'
            WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        RankedMovies rm
    LEFT JOIN EarlyDirectors ed ON rm.title_id = ed.movie_id
    WHERE 
        rm.title_rank <= 5
)

SELECT 
    md.title,
    md.production_year,
    md.title_rank,
    md.keyword_count,
    md.director_count,
    md.cast_size,
    CASE 
        WHEN md.director_count IS NULL THEN 'No Directors'
        WHEN md.director_count > 2 THEN 'Multiple Directors'
        ELSE 'Single Director'
    END AS director_info
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC,
    md.title_rank
LIMIT 50;
