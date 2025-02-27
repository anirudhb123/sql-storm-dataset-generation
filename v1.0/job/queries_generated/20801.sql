WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(i.yearly_income) AS avg_income
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    LEFT JOIN (
        SELECT 
            p.person_id, 
            (10000 + (RANDOM() * 50000)) AS yearly_income
        FROM person_info p
    ) i ON a.person_id = i.person_id
    GROUP BY a.person_id, a.name
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
TitleInfo AS (
    SELECT 
        tt.title_id,
        tt.title,
        tt.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM RankedTitles tt
    LEFT JOIN MovieKeywords mk ON tt.title_id = mk.movie_id
),
HighProfileActors AS (
    SELECT 
        actor.person_id,
        actor.name,
        actor.movie_count,
        actor.avg_income
    FROM ActorMovies actor
    WHERE actor.avg_income > (SELECT AVG(avg_income) FROM ActorMovies)
)
SELECT 
    ti.title,
    ti.production_year,
    COALESCE(actors_actor.name, 'Unknown Actor') AS actor_name,
    ti.keywords
FROM TitleInfo ti
LEFT JOIN HighProfileActors actors_actor ON ti.title_id IN (
    SELECT ci.movie_id
    FROM cast_info ci
    WHERE ci.person_id = actors_actor.person_id
)
WHERE ti.production_year > 2000 
    AND ti.keywords NOT LIKE '%Sequel%'
ORDER BY ti.production_year DESC, ti.title;
