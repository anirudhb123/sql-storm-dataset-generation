WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorStats AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        AVG(mt.production_year) AS average_movie_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    WHERE 
        ci.role_id IN (SELECT id FROM role_type WHERE role LIKE '%actor%')
    GROUP BY 
        a.id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(as.movie_count, 0) AS movie_count,
    COALESCE(as.average_movie_year, 0) AS average_movie_year,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN mh.level > 1 THEN 'Chained Movie'
        ELSE 'Standalone Movie'
    END AS movie_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorStats as ON mh.movie_id = as.actor_id
LEFT JOIN 
    KeywordStats ks ON mh.movie_id = ks.movie_id
WHERE 
    mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC, 
    mh.title ASC;
This SQL query provides an intricate performance benchmark setup utilizing the specified tables and constructs. It incorporates:

1. A recursive CTE `MovieHierarchy` to build a hierarchy of movies based on linked movies from the `movie_link` table.
2. An aggregate subquery `ActorStats` to gather stats on actors, including the count of movies they've been in and their average production year.
3. Another aggregate subquery `KeywordStats` to count distinct keywords associated with each movie.
4. The final selection combines data from the recursive CTE and the subqueries, applying outer joins to ensure all movies are represented, even if some stats are missing.
5. The use of CASE logic to classify movies based on their relationship in the link hierarchy.
6. Inclusion of `COALESCE` to handle potential NULL values resulting from outer joins. 

Overall, this query exemplifies complexities with varying SQL constructs, showcasing JOIN operations, aggregate functions, and hierarchical queries.
