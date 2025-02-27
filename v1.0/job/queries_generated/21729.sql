WITH MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword AS mt
    JOIN
        keyword AS k ON mt.keyword_id = k.id
    GROUP BY
        mt.movie_id
), 
MovieWithDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
        CASE 
            WHEN t.production_year < 2000 THEN 'Classic'
            WHEN t.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        title AS t
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id 
    LEFT JOIN 
        MovieKeywords AS mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY era ORDER BY cast_count DESC) AS cast_rank
    FROM 
        MovieWithDetails
)
SELECT 
    *,
    CASE 
        WHEN cast_rank IS NULL THEN 'No Cast'
        WHEN cast_count = 0 THEN 'Empty Cast'
        ELSE 'Featured'
    END AS cast_status,
    CONCAT('Movie: ', title, ' | Era: ', era, ' | Keywords: ', movie_keywords) AS description
FROM 
    RankedMovies
WHERE
    production_year IS NOT NULL
    AND (era = 'Classic' OR (era = 'Recent' AND cast_count > 2))
ORDER BY 
    production_year DESC, cast_count DESC;
