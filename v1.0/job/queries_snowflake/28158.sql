
WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS production_company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank_with_keywords
    FROM title m
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    WHERE m.production_year IS NOT NULL
    GROUP BY m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT movie_id, title, production_year
    FROM RankedMovies
    WHERE rank_with_keywords <= 5
),
ActorDetails AS (
    SELECT
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movies
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    WHERE a.name IS NOT NULL
    GROUP BY a.person_id, a.name
),
MovieActors AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        ad.person_id,
        ad.name
    FROM TopMovies tm
    JOIN cast_info ci ON tm.movie_id = ci.movie_id
    JOIN ActorDetails ad ON ad.person_id = ci.person_id
)
SELECT
    ma.title,
    ma.production_year,
    COUNT(DISTINCT ma.name) AS actor_count,
    LISTAGG(DISTINCT ma.name, ', ') WITHIN GROUP (ORDER BY ma.name) AS actor_names,
    mc.production_company_count,
    mc.keyword_count
FROM MovieActors ma
JOIN RankedMovies mc ON ma.movie_id = mc.movie_id
GROUP BY ma.title, ma.production_year, mc.production_company_count, mc.keyword_count
ORDER BY ma.production_year DESC, actor_count DESC;
