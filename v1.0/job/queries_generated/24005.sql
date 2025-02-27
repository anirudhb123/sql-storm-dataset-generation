WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_count_rank
    FROM aka_title mt
    JOIN cast_info ci ON mt.id = ci.movie_id
    GROUP BY mt.id, mt.title, mt.production_year
),
ActorAssociations AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ct.id) AS associated_movies,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 1 ELSE 0 END) AS no_order_movies
    FROM aka_name ak
    LEFT JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN aka_title at ON ci.movie_id = at.id 
    LEFT JOIN role_type rt ON ci.role_id = rt.id 
    GROUP BY ak.person_id, ak.name
),
NotableActors AS (
    SELECT 
        aa.person_id,
        aa.name,
        aa.associated_movies,
        RANK() OVER (ORDER BY aa.associated_movies DESC) AS rank_movies
    FROM ActorAssociations aa
    WHERE aa.associated_movies > 10
)
SELECT 
    nm.id AS actor_id,
    nm.name,
    nm.gender,
    rm.movie_id,
    rm.title,
    rm.production_year,
    ra.no_order_movies,
    (SELECT COUNT(DISTINCT mk.keyword) FROM movie_keyword mk WHERE mk.movie_id = rm.movie_id) AS keyword_count,
    COALESCE(ra.no_order_movies, 0) AS null_handling_demo
FROM NotableActors na
JOIN aka_name nm ON na.person_id = nm.person_id
JOIN RankedMovies rm ON rm.actor_count_rank <= 5
LEFT JOIN ActorAssociations ra ON nm.person_id = ra.person_id
WHERE nm.gender IS NOT NULL 
    AND (EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = rm.movie_id AND mi.info_type_id = 2 AND mi.info LIKE '%Oscar%') 
        OR rm.production_year > 2000)
ORDER BY rm.production_year DESC, na.rank_movies ASC, rm.title ASC;

-- Potentially bizarre case: Joining on potentially empty results, using correlated subquery for keyword counts, 
-- a combination of left joins to show null logic, and unusual predicates to filter notable actors.
