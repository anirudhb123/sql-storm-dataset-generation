WITH RecursiveMovieCast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.nr_order IS NOT NULL -- ensuring we only consider ordered roles
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
)
SELECT 
    at.title,
    rmc.actor_name,
    COALESCE(mwk.keywords, 'No keywords') AS keywords,
    mt.production_year,
    COUNT(DISTINCT m.movie_id) OVER (PARTITION BY mt.production_year) AS total_movies_by_year,
    CASE 
        WHEN mt.production_year = (SELECT MAX(production_year) FROM aka_title) THEN 'Latest'
        ELSE 'Not Latest'
    END AS release_status
FROM 
    aka_title at
LEFT JOIN 
    RecursiveMovieCast rmc ON at.id = rmc.movie_id
LEFT JOIN 
    MoviesWithKeywords mwk ON at.id = mwk.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%trivia%')
LEFT JOIN 
    complete_cast cc ON at.id = cc.movie_id
JOIN 
    title mt ON at.id = mt.id
WHERE 
    mt.production_year IS NOT NULL
    AND (cc.status_id IS NULL OR cc.status_id = 1) -- assume status 1 is active
ORDER BY 
    mt.production_year DESC, total_movies_by_year ASC, rmc.actor_rank;
