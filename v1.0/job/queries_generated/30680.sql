WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level,
        ARRAY[m.id] AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        mk.linked_movie_id,
        m.title,
        mh.level + 1,
        path || mk.linked_movie_id
    FROM 
        movie_link mk
    JOIN 
        MovieHierarchy mh ON mk.movie_id = mh.movie_id
    JOIN 
        aka_title m ON mk.linked_movie_id = m.id
),
ActorStats AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        AVG(years_since_first) AS avg_years_since_first,
        COUNT(DISTINCT CASE WHEN ci.note IS NULL THEN 1 END) AS null_notes_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        (SELECT 
             person_id,
             MIN(EXTRACT(YEAR FROM t.production_year)) AS years_since_first
         FROM 
             cast_info c
         JOIN 
             aka_title t ON c.movie_id = t.id
         GROUP BY 
             person_id) AS first_movies ON a.person_id = first_movies.person_id
    GROUP BY 
        a.id, a.name
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    COALESCE(as.total_movies, 0) AS actor_movie_count,
    as.avg_years_since_first,
    as.null_notes_count,
    mk.keywords,
    CASE 
        WHEN mh.level = 1 THEN 'Top Level' 
        ELSE 'Linked' 
    END AS level_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorStats as ON mh.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name WHERE name ILIKE '%Smith%'))
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.movie_id IS NOT NULL
ORDER BY 
    mh.level, as.total_movies DESC, mh.title;
