WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT mw.id) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mw ON a.id = mw.movie_id
    GROUP BY 
        a.title, a.production_year
), 
RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_within_year
    FROM 
        MovieDetails
)
SELECT 
    mw.movie_title,
    mw.production_year,
    mw.cast_count,
    mw.actor_names,
    CASE 
        WHEN mw.keyword_count > 5 THEN 'Popular'
        WHEN mw.keyword_count IS NULL THEN 'No keywords'
        ELSE 'Less Popular' 
    END AS popularity_status
FROM 
    RankedMovies mw
WHERE 
    mw.rank_within_year <= 5
ORDER BY 
    mw.production_year ASC, mw.rank_within_year ASC;

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT m.id) AS movie_count
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    aka_title m ON c.movie_id = m.id
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT m.id) > 10
UNION ALL
SELECT 
    'Unknown Actor' AS actor_name,
    COUNT(DISTINCT m.id) AS movie_count
FROM 
    aka_title m
WHERE 
    m.id NOT IN (SELECT movie_id FROM cast_info)
GROUP BY 
    'Unknown Actor';

