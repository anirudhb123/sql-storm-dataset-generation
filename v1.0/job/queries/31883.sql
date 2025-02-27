
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level 
    FROM 
        aka_title m 
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 
    FROM 
        aka_title m 
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
AggregatedCast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS total_keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ac.total_cast, 0) AS total_cast,
        COALESCE(kc.total_keywords, 0) AS total_keywords,
        mh.level,
        ac.actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        AggregatedCast ac ON mh.movie_id = ac.movie_id
    LEFT JOIN 
        KeywordCount kc ON mh.movie_id = kc.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.total_keywords,
    CASE 
        WHEN fm.total_cast = 0 THEN 'No cast information'
        ELSE fm.actor_names
    END AS actor_info,
    ROW_NUMBER() OVER (PARTITION BY fm.level ORDER BY fm.production_year DESC) AS rank
FROM 
    FilteredMovies fm
WHERE 
    fm.production_year > 2000
ORDER BY 
    fm.level,
    fm.total_cast DESC,
    fm.production_year DESC
LIMIT 50;
