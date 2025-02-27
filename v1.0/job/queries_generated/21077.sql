WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title,
        COUNT(*) OVER(PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        CASE 
            WHEN rm.production_year < 2000 THEN 'Classic Movie'
            WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern Movie'
            ELSE 'Recent Movie'
        END AS movie_age_category,
        COALESCE(mk.keywords, 'No Keywords') AS movie_keywords
    FROM 
        RankedMovies rm
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        INNER JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) AS mk ON rm.movie_id = mk.movie_id
),
CastCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        MIN(ci.nr_order) AS first_cast_order,
        MAX(ci.nr_order) AS last_cast_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.movie_age_category,
        cc.cast_count,
        cc.first_cast_order,
        cc.last_cast_order,
        CASE 
            WHEN cc.cast_count IS NULL THEN 'No Cast Available'
            WHEN cc.first_cast_order IS NOT NULL AND cc.last_cast_order IS NOT NULL AND cc.first_cast_order < cc.last_cast_order THEN 'Full Cast'
            ELSE 'Incomplete Cast'
        END AS cast_availability
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastCounts cc ON md.movie_id = cc.movie_id
)
SELECT 
    title,
    production_year,
    movie_age_category,
    cast_count,
    first_cast_order,
    last_cast_order,
    cast_availability,
    RANK() OVER(ORDER BY production_year DESC, title) AS movie_rank
FROM 
    FinalResults
WHERE 
    movie_age_category IS NOT NULL 
    AND (cast_count IS NULL OR cast_count > 5)
ORDER BY 
    production_year DESC,
    title;
