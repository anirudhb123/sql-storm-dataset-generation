WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS rn
    FROM title t
),
ActorMovieCounts AS (
    SELECT
        ai.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN aka_name ai ON ci.person_id = ai.person_id
    GROUP BY ai.person_id
),
TopActors AS (
    SELECT
        a.person_id,
        a.name,
        rm.movie_count
    FROM aka_name a
    JOIN ActorMovieCounts rm ON a.person_id = rm.person_id
    WHERE rm.movie_count >= 5
    ORDER BY rm.movie_count DESC
    LIMIT 10
)
SELECT
    tt.title AS movie_title,
    tt.production_year,
    ta.name AS top_actor,
    ta.movie_count AS top_actor_movies,
    k.keyword AS related_keyword
FROM RankedTitles tt
JOIN movie_keyword mk ON tt.title_id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN TopActors ta ON ta.person_id IN (
    SELECT ci.person_id
    FROM cast_info ci
    WHERE ci.movie_id = tt.title_id
)
WHERE tt.rn <= 3
ORDER BY tt.production_year DESC, tt.title;
