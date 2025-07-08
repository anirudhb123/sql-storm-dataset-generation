
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT kc.keyword_id) DESC) AS rank_by_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword kc ON t.id = kc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mc.cast_count, 0) AS total_cast,
        COALESCE(mc.cast_names, 'No Cast') AS cast_names,
        COALESCE(rm.keyword_count, 0) AS keyword_count,
        rm.rank_by_keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    md.keyword_count,
    CASE 
        WHEN md.total_cast > 10 THEN 'Large Cast' 
        WHEN md.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast' 
        ELSE 'Small Cast' 
    END AS cast_size
FROM 
    MovieDetails md
WHERE 
    md.rank_by_keywords <= 5 
    OR (md.production_year >= 2000 AND md.keyword_count > 0)
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
