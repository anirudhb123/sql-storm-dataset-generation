WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
),
ActorMovieCounts AS (
    SELECT 
        actor_name,
        COUNT(*) AS total_movies,
        MIN(production_year) AS first_movie_year,
        MAX(production_year) AS last_movie_year
    FROM RankedTitles
    GROUP BY actor_name
),
PopularKeywords AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM keyword k
    JOIN movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY k.keyword
    ORDER BY keyword_count DESC
    LIMIT 10
)
SELECT 
    am.actor_name,
    am.total_movies,
    am.first_movie_year,
    am.last_movie_year,
    pk.keyword,
    pk.keyword_count
FROM ActorMovieCounts am
JOIN PopularKeywords pk ON am.total_movies > 5
ORDER BY am.total_movies DESC, pk.keyword_count DESC;
