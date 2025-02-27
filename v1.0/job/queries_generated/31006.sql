WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS level
    FROM title mt
    WHERE mt.production_year = (SELECT MAX(production_year) FROM title)

    UNION ALL

    SELECT
        ml.linked_movie_id,
        m.title,
        mh.level + 1
    FROM movie_link ml
    JOIN title m ON ml.linked_movie_id = m.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        AVG(yi.info::int) as avg_years_active
    FROM title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN person_info pi ON ci.person_id = pi.person_id
    LEFT JOIN movie_info yi ON m.id = yi.movie_id AND yi.info_type_id = (SELECT id FROM info_type WHERE info = 'Years Active')
    GROUP BY m.id, m.title
    HAVING COUNT(DISTINCT ci.person_id) > 5
),
EnrichedMovies AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.num_cast_members,
        mh.level,
        CASE 
            WHEN tm.num_cast_members >= 10 THEN 'High'
            WHEN tm.num_cast_members BETWEEN 6 AND 9 THEN 'Medium'
            ELSE 'Low'
        END AS cast_size_category
    FROM TopMovies tm
    LEFT JOIN MovieHierarchy mh ON tm.movie_id = mh.movie_id
)
SELECT
    em.movie_id,
    em.title,
    em.num_cast_members,
    em.level,
    em.cast_size_category,
    COALESCE(ceil(AVG(CASE WHEN mci.kind IS NULL THEN 0 ELSE 1 END)) OVER (PARTITION BY em.movie_id), 0) AS avg_company_count
FROM EnrichedMovies em
LEFT JOIN movie_companies mci ON em.movie_id = mci.movie_id
GROUP BY em.movie_id, em.title, em.num_cast_members, em.level, em.cast_size_category
ORDER BY em.num_cast_members DESC, em.level;
This query first creates a common table expression (CTE) to establish a recursive hierarchy of movies linked to the most recent production year. It then calculates the number of cast members and averages for active years of movies with at least five distinct cast members. An enriched dataset is generated to classify movies based on cast size. Finally, it computes the average company counts associated with those movies and presents the results sorted by the number of cast members, providing essential benchmarking information for performance analysis.
