WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.movie_id,
        mh.depth + 1
    FROM 
        aka_title mt
    INNER JOIN movie_link ml ON mt.id = ml.linked_movie_id
    INNER JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
top_movies AS (
    SELECT 
        m.movie_id,
        m.title, 
        COUNT(DISTINCT c.id) AS num_cast
    FROM 
        movie_hierarchy m
    LEFT JOIN cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id, m.title
    HAVING 
        COUNT(DISTINCT c.id) > 5 
),
movies_with_keywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id, mt.title
),
final_selection AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        tc.num_cast,
        mk.keywords
    FROM 
        top_movies tc
    JOIN movies_with_keywords mk ON tc.movie_id = mk.movie_id
    WHERE 
        tc.num_cast > (
            SELECT AVG(num_cast)
            FROM top_movies
        )
),
person_stats AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT cf.movie_id) AS movies_count,
        SUM(CASE WHEN cf.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes
    FROM 
        cast_info cf
    JOIN aka_name ca ON cf.person_id = ca.person_id
    GROUP BY 
        ca.person_id
)
SELECT 
    fs.movie_title,
    fs.production_year,
    fs.num_cast,
    fs.keywords,
    ps.movies_count,
    ps.has_notes
FROM 
    final_selection fs
LEFT JOIN person_stats ps ON fs.num_cast = ps.movies_count
ORDER BY 
    fs.production_year DESC NULLS LAST, 
    fs.num_cast DESC, 
    fs.movie_title;
