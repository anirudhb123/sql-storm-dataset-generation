WITH RECURSIVE MovieHierarchy AS (
    SELECT
        ct.movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM
        complete_cast cc
    JOIN title t ON cc.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE
        cn.country_code IS NOT NULL
    UNION ALL
    SELECT
        cc.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM
        complete_cast cc
    JOIN title t ON cc.movie_id = t.id
    JOIN MovieHierarchy mh ON cc.movie_id = mh.movie_id
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    WHERE
        ml.link_type_id IS NOT NULL
),
ActorTitles AS (
    SELECT
        an.name AS actor_name,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS production_companies_count,
        ROW_NUMBER() OVER (PARTITION BY an.id ORDER BY t.production_year DESC) AS recent_title_rank
    FROM
        aka_name an
    JOIN cast_info ci ON an.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    WHERE
        an.name IS NOT NULL
    GROUP BY
        an.id, an.name, t.title, t.production_year
),
HighestRankedActors AS (
    SELECT
        actor_name,
        title,
        production_year,
        production_companies_count
    FROM
        ActorTitles
    WHERE
        recent_title_rank = 1
        AND production_companies_count > 1
),
FinalResult AS (
    SELECT
        ha.actor_name,
        ha.title,
        ha.production_year,
        COUNT(mv.movie_id) AS related_movies_count,
        STRING_AGG(DISTINCT t2.title, ', ') AS related_movies_titles
    FROM
        HighestRankedActors ha
    LEFT JOIN movie_link ml ON ha.title = ml.linked_movie_id
    LEFT JOIN title t2 ON ml.linked_movie_id = t2.id
    LEFT JOIN complete_cast mv ON t2.id = mv.movie_id
    GROUP BY
        ha.actor_name, ha.title, ha.production_year
)
SELECT
    fr.actor_name,
    fr.title,
    fr.production_year,
    fr.related_movies_count,
    fr.related_movies_titles
FROM
    FinalResult fr
WHERE
    fr.related_movies_count > 0
ORDER BY
    fr.production_year DESC, fr.actor_name;
