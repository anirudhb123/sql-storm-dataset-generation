WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.id IS NOT NULL
    UNION ALL
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.movie_id
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank,
        COALESCE(ca.name, 'Unknown') AS cast_member,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, ca.name
),
movies_with_keywords AS (
    SELECT 
        m.movie_id,
        m.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title
)
SELECT 
    mh.movie_id, 
    mh.movie_title, 
    COALESCE(mvk.keywords, 'No Keywords') AS keywords,
    rm.rank,
    rm.cast_member,
    rm.info_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movies_with_keywords mvk ON mh.movie_id = mvk.movie_id
LEFT JOIN 
    ranked_movies rm ON mh.movie_id = rm.movie_id
WHERE 
    rm.rank <= 5 AND mvk.keywords IS NOT NULL
ORDER BY 
    mh.level, mvk.keywords;

This SQL query demonstrates various SQL features:
1. A recursive CTE (`movie_hierarchy`) to build a hierarchy of movies that are linked to one another.
2. A window function (`ROW_NUMBER()`) to rank movies based on their production years.
3. Outer joins to gather information about cast members and movie keywords without losing movies that may not have those elements.
4. Aggregation of keywords using `STRING_AGG`.
5. Filtering based on the rank and ensuring that we include movies with keywords through a combination of conditions and NULL logic.
6. The query is designed to yield a comprehensive view of the hierarchy of movies, revealing their keywords and cast members while handling selectivity with performance considerations in mind.
