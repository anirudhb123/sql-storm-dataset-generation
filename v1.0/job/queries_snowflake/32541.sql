
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        id,
        movie_id,
        linked_movie_id,
        1 AS level
    FROM movie_link
    WHERE movie_id IN (SELECT id FROM title WHERE production_year >= 2000)

    UNION ALL

    SELECT
        ml.id,
        ml.movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON mh.linked_movie_id = ml.movie_id
), MovieDetails AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        MAX(CASE WHEN ci.role_id = (SELECT id FROM role_type WHERE role = 'Actor') THEN ca.person_id END) AS main_actor_id
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = t.id
    LEFT JOIN aka_name ca ON ci.person_id = ca.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
), ActorDetails AS (
    SELECT
        an.person_id,
        an.name,
        COUNT(DISTINCT md.title_id) AS movie_count,
        AVG(md.production_year) AS avg_year
    FROM MovieDetails md
    JOIN aka_name an ON md.main_actor_id = an.person_id
    GROUP BY an.person_id, an.name
), RankedActors AS (
    SELECT
        ad.person_id,
        ad.name,
        ad.movie_count,
        ad.avg_year,
        ROW_NUMBER() OVER (ORDER BY ad.movie_count DESC, ad.avg_year DESC) AS rank
    FROM ActorDetails ad
)
SELECT 
    ra.name AS actor_name,
    ra.movie_count,
    ra.avg_year,
    (SELECT LISTAGG(movie.title, ', ' ORDER BY movie.production_year DESC)
     FROM title movie 
     JOIN complete_cast cc ON movie.id = cc.movie_id
     WHERE cc.subject_id = ra.person_id) AS movies_played
FROM RankedActors ra
WHERE ra.rank <= 10
ORDER BY ra.movie_count DESC;
