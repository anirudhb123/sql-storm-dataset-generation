WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.production_year IS NOT NULL AND m.kind_id IN (1, 2)  -- Assuming 1 and 2 are movie types

    UNION ALL

    SELECT
        m.id AS movie_id,
        CONCAT(h.movie_title, ' -> ', m.title) AS movie_title,
        m.production_year,
        h.level + 1
    FROM title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN MovieHierarchy h ON h.movie_id = ml.movie_id
)
SELECT
    mh.movie_title,
    mh.production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT cc.subject_id) AS complete_cast_count,
    AVG(mr.rating) AS average_rating,
    CASE 
        WHEN AVG(mr.rating) IS NULL THEN 'No Ratings'
        WHEN AVG(mr.rating) >= 8 THEN 'Highly Rated'
        WHEN AVG(mr.rating) >= 5 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS rating_category
FROM MovieHierarchy mh
LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN keyword kw ON kw.id = mk.keyword_id
LEFT JOIN complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN (
    SELECT
        movie_id,
        AVG(rating) AS rating
    FROM (
        SELECT
            movie_id,
            COALESCE(info::NUMERIC, 0) AS rating
        FROM movie_info 
        WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    ) AS ratings
    GROUP BY movie_id
) mr ON mr.movie_id = mh.movie_id
WHERE mh.production_year BETWEEN 2000 AND 2020
GROUP BY mh.movie_title, mh.production_year
ORDER BY mh.production_year DESC, AVG(mr.rating) DESC NULLS LAST;

This SQL query accomplishes several objectives:
1. **Recursive CTE** `MovieHierarchy` to navigate movie linkages.
2. **Aggregation** with `STRING_AGG` to collect actors and keywords.
3. **Calculations** to count complete casts and calculate the average rating of movies.
4. **Conditional logic** to classify movies based on their average ratings.
5. **Outer joins** to ensure that movies without actors, keywords, or ratings are still included in the final output.
6. **Filtering** of movies based on production year and kind, showcasing movies produced between 2000 and 2020.

This provides a comprehensive view of the relevant movies alongside their metadata and relationships.
