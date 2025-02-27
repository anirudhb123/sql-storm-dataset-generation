WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        mt.title, mt.production_year
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
TitleWithKeywords AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.title = mk.movie_id
)

SELECT 
    twk.title,
    twk.production_year,
    twk.total_cast,
    twk.keywords,
    COALESCE(CAST(NULLIF(twk.production_year, 0) AS VARCHAR), 'Unknown Year') AS formatted_year,
    CASE 
        WHEN twk.total_cast = 0 THEN 'No Cast'
        WHEN twk.total_cast > 10 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_category
FROM 
    TitleWithKeywords twk
WHERE 
    twk.total_cast > 2 OR twk.keywords != 'No Keywords'
ORDER BY 
    twk.production_year DESC, twk.total_cast DESC
LIMIT 15;

-- Additional complex logic to ensure understanding of how NULL cases are handled:
SELECT 
    t.title,
    COALESCE(mci.info, 'No Info') AS movie_info,
    ni.name AS actor_name,
    CASE 
        WHEN ni.name IS NULL THEN 'Unknown Actor'
        ELSE ni.name
    END AS released_by_actor,
    CASE 
        WHEN MATCH (t.title) AGAINST ('+Tragedy' IN BOOLEAN MODE) THEN 'Tragic'
        ELSE 'Not Tragic'
    END AS tragedy_classification
FROM 
    title t
LEFT JOIN 
    movie_info mci ON mci.movie_id = t.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = t.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = t.id
LEFT JOIN 
    aka_name ni ON ci.person_id = ni.person_id
WHERE 
    t.production_year IS NOT NULL
    AND (ci.note IS NULL OR ci.note != '')
ORDER BY 
    tragedy_classification, t.production_year DESC
LIMIT 10;
