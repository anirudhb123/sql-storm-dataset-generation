WITH RECURSIVE MoviePaths AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level,
        m.production_year,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000 -- Start from movies released after 2000

    UNION ALL 

    SELECT 
        m.id,
        m.title,
        mp.level + 1,
        m.production_year,
        mp.movie_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        MoviePaths mp ON ml.movie_id = mp.movie_id
    WHERE 
        mp.level < 3 -- Limit to depth of 3 levels of linked movies
),
RankedActors AS (
    SELECT 
        ai.person_id,
        an.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        ROW_NUMBER() OVER (PARTITION BY ai.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM MoviePaths) -- Actors in the movie paths
    GROUP BY 
        ai.person_id,
        an.name
),
MoviesWithStars AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT ra.actor_name) AS star_actors
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        RankedActors ra ON ci.person_id = ra.person_id
    WHERE 
        ra.rank <= 3 -- Top 3 actors
    GROUP BY 
        m.id, m.title
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.star_actors,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mw.movie_id) AS keyword_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mw.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')) AS summary_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = mw.movie_id) IS NULL THEN 'No Cast Info' 
        ELSE 'Has Cast Info' 
    END AS cast_status
FROM 
    MoviesWithStars mw
ORDER BY 
    mw.title;
