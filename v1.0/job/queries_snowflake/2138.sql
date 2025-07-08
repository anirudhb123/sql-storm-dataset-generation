
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mn.name, 'Unknown') AS main_actor,
        CASE 
            WHEN rm.cast_count > 10 THEN 'High'
            WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS cast_size_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name mn ON ci.person_id = mn.person_id 
    WHERE 
        rm.rank_within_year = 1
),
MovieKeywordStats AS (
    SELECT 
        mv.movie_id,
        LISTAGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mv
    JOIN 
        keyword kw ON mv.keyword_id = kw.id
    GROUP BY 
        mv.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.main_actor,
    md.cast_count,
    md.cast_size_category,
    COALESCE(mks.keywords, 'No keywords') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    MovieKeywordStats mks ON md.movie_id = mks.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 10;
