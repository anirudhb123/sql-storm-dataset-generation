WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(DISTINCT mk.keyword_id) OVER (PARTITION BY at.id) AS keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    WHERE 
        at.production_year >= 2000
),
DistinctCast AS (
    SELECT DISTINCT 
        ci.movie_id,
        ak.name AS actor_name,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        dc.actor_name,
        COALESCE(dc.nr_order, 0) AS order_num
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DistinctCast dc ON rm.movie_id = dc.movie_id
)
SELECT 
    mwc.title,
    mwc.production_year,
    STRING_AGG(mwc.actor_name, ', ') AS actor_list,
    AVG(CASE WHEN mwc.order_num > 0 THEN mwc.order_num END) AS avg_order,
    COUNT(DISTINCT mk.keyword_id) AS unique_keywords,
    (SELECT MAX(l.link_type_id) 
     FROM movie_link l 
     WHERE l.movie_id = mwc.movie_id) AS max_link_type_id,
    (CASE 
        WHEN COUNT(DISTINCT mk.keyword_id) > 5 THEN 'High'
        WHEN COUNT(DISTINCT mk.keyword_id) BETWEEN 2 AND 5 THEN 'Moderate'
        ELSE 'Low'
    END) AS keyword_engagement
FROM 
    MoviesWithCast mwc
LEFT JOIN 
    movie_keyword mk ON mwc.movie_id = mk.movie_id
GROUP BY 
    mwc.title, mwc.production_year
HAVING 
    COUNT(mwc.actor_name) > 0 
    AND (COUNT(DISTINCT mk.keyword_id) > 0 OR 
         EXISTS (SELECT * FROM movie_info mi WHERE mi.movie_id = mwc.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')))
ORDER BY 
    mwc.production_year DESC, avg_order ASC
LIMIT 50;
