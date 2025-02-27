WITH RECURSIVE MovieHierarchy AS (
    -- This CTE recursively selects all movies with their links
    SELECT 
        m.id AS movie_id,
        m.title,
        ml.linked_movie_id,
        0 AS level
    FROM title m
    LEFT JOIN movie_link ml ON m.id = ml.movie_id

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        ml.linked_movie_id,
        mh.level + 1
    FROM title m
    INNER JOIN movie_link ml ON m.id = ml.movie_id
    INNER JOIN MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
),
ActorRankings AS (
    -- This CTE calculates the ranking of actors based on the number of movies they've appeared in
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM cast_info ci
    GROUP BY ci.person_id
),
CompanyCounts AS (
    -- CTE summarizing the number of companies producing movies by year
    SELECT 
        mc.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN aka_title at ON mc.movie_id = at.movie_id
    GROUP BY mc.production_year
),
MovieKeywords AS (
    -- CTE to aggregate keywords for each movie
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    t.title AS movie_title,
    mh.linked_movie_id AS linked_movie_id,
    COALESCE(AK.actor_name, 'Unknown Actor') AS main_actor,
    COALESCE(CC.company_count, 0) AS number_of_companies,
    COALESCE(MK.keywords, 'No keywords available') AS keywords,
    AH.movie_count AS actor_movie_count,
    MH.level AS link_level
FROM title t
LEFT JOIN MovieHierarchy mh ON t.id = mh.movie_id
LEFT JOIN (
    SELECT 
        a.name AS actor_name,
        ci.person_id
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    WHERE ci.nr_order = 1
) AK ON AK.person_id = (
    SELECT person_id 
    FROM cast_info ci 
    WHERE ci.movie_id = t.id 
    AND ci.nr_order = 1 LIMIT 1
)
LEFT JOIN CompanyCounts CC ON t.production_year = CC.production_year
LEFT JOIN MovieKeywords MK ON t.id = MK.movie_id
LEFT JOIN ActorRankings AH ON AH.person_id = AK.person_id
WHERE t.production_year IS NOT NULL 
AND t.title IS NOT NULL 
ORDER BY t.production_year DESC, link_level ASC;

This SQL query uses multiple advanced concepts such as recursive CTEs to generate movie hierarchies, aggregated CTEs to summarize information about companies and keywords, window functions to rank actors based on their movie appearances, and outer joins to ensure no data loss. The results are ordered by production year and link level, providing a comprehensive performance benchmark across the movie data schema.
