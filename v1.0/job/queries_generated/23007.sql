WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        NULL AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
, movie_data AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COALESCE(NULLIF(mk.keyword, ''), 'No keyword') AS keyword,
        COUNT(DISTINCT ci.id) AS cast_count,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND cc.movie_id = ci.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.level, mk.keyword
)
, ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY md.keyword ORDER BY md.cast_count DESC) AS rank_within_keyword
    FROM 
        movie_data md
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.keyword,
    r.cast_count,
    r.roles_count,
    CASE 
        WHEN r.rank_within_keyword = 1 THEN 'Top Movie' 
        ELSE 'Regular Movie' 
    END AS movie_rank_status
FROM 
    ranked_movies r
WHERE 
    r.level = 0
    AND r.cast_count > (
        SELECT 
            AVG(cast_count) FROM ranked_movies WHERE keyword IS NOT NULL
    )
ORDER BY 
    r.production_year DESC,
    r.keyword,
    r.cast_count DESC
LIMIT 50;

This SQL query performs the following operations:

1. It constructs a recursive Common Table Expression (CTE) called `movie_hierarchy` to generate a hierarchy of movies that are linked to each other.

2. It aggregates movie data into the `movie_data` CTE, calculating the total number of cast members and the roles count for each movie, while handling NULL values for keywords.

3. It ranks the movies within each keyword group in the `ranked_movies` CTE, using the `RANK()` window function.

4. Finally, it retrieves a filtered list of top-ranked movies based on cast count, excluding movies below average cast numbers, asserting conditions related to hierarchy levels and additional ranking logic.

The query ends by limiting the output to 50 records, offering complex interactions amongst the various tables as per the benchmark schema requirements.
