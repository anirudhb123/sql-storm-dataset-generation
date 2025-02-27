WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_stats AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN r.role = 'Director' THEN c.person_id END) AS total_directors
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast_members,
    COALESCE(cs.total_directors, 0) AS total_directors,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    mh.level AS movie_level,
    CASE 
        WHEN mh.level = 1 THEN 'Root Movie'
        WHEN mh.level > 1 AND mh.level <= 3 THEN 'Series'
        ELSE 'Deep Series'
    END AS movie_category
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_stats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.level, m.production_year DESC
LIMIT 100;

This SQL query performs several operations:
1. It uses a recursive CTE (`movie_hierarchy`) to establish a hierarchy of movies and episodes based on relationships defined by `episode_of_id`.
2. It calculates statistics about cast members in another CTE (`cast_stats`), counting the total cast and total directors per movie.
3. The `movie_keywords` CTE aggregates keywords associated with each movie.
4. The main query combines results from the hierarchy with cast statistics and keywords, categorizing movies based on their hierarchy level and ordering the result set by level and production year, with a limit of 100 results. The use of `COALESCE` ensures that even movies with no cast or keywords are still represented with default values.
