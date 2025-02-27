WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        array_agg(cast.person_id) AS cast_members,
        row_number() OVER (PARTITION BY m.id ORDER BY c.id) AS cast_rank
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        cast_info cast ON m.id = cast.movie_id
    LEFT JOIN
        aka_name c ON cast.person_id = c.person_id
    WHERE
        m.production_year >= 2000
    GROUP BY
        m.id, m.title, mk.keyword
),
keyword_summary AS (
    SELECT
        keyword,
        COUNT(movie_id) AS total_movies,
        COUNT(DISTINCT unnest(cast_members)) AS unique_cast_members
    FROM
        movie_hierarchy
    GROUP BY
        keyword
),
top_keywords AS (
    SELECT
        keyword,
        total_movies,
        unique_cast_members,
        RANK() OVER (ORDER BY total_movies DESC) AS keyword_rank
    FROM
        keyword_summary
),
cross_movie_links AS (
    SELECT
        m1.title AS movie_title,
        m2.title AS linked_movie_title,
        lt.link AS link_type
    FROM
        movie_link ml
    JOIN
        aka_title m1 ON ml.movie_id = m1.id
    JOIN
        aka_title m2 ON ml.linked_movie_id = m2.id
    JOIN
        link_type lt ON ml.link_type_id = lt.id
)
SELECT
    k.keyword,
    k.total_movies,
    k.unique_cast_members,
    CASE
        WHEN k.keyword_rank <= 3 THEN 'High' 
        WHEN k.keyword_rank BETWEEN 4 AND 10 THEN 'Medium' 
        ELSE 'Low' 
    END AS keyword_popularity,
    ARRAY_AGG(DISTINCT cml.movie_title) AS linked_movies,
    COUNT(DISTINCT cml.linked_movie_title) AS num_linked_movies
FROM
    top_keywords k
LEFT JOIN
    cross_movie_links cml ON k.keyword ILIKE '%' || substring(cml.movie_title FROM '[0-9]') || '%'
GROUP BY
    k.keyword, k.total_movies, k.unique_cast_members, k.keyword_rank
ORDER BY
    k.total_movies DESC NULLS LAST;

This SQL query:
- Utilizes CTEs to build a movie hierarchy, summarize keywords, and identify linked movies.
- Implements window functions for ranking keywords based on movie counts.
- Employs string expressions with pattern matching to correlate linked movies with keywords based on their title.
- Includes outer joins to collect all movies and their associated keywords/cast members, even if some entities are absent.
- Computes contributions of cast members uniquely associated with each keyword.
- Classifies keyword popularity into 'High', 'Medium', and 'Low' based on their rank, demonstrating nested conditional logic.
- Uses `NULLS LAST` in the order clause to deal with potential null results from joins.
