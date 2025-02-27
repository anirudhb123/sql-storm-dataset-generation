WITH MovieCast AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ak.name AS actor_name,
        r.role AS role_name
    FROM aka_title AS a
    JOIN cast_info AS c ON a.id = c.movie_id
    JOIN aka_name AS ak ON c.person_id = ak.person_id
    JOIN role_type AS r ON c.role_id = r.id
    WHERE a.production_year >= 2000
      AND r.role LIKE '%Actor%'
),
MovieKeywords AS (
    SELECT 
        a.title AS movie_title,
        m.keyword AS keyword
    FROM aka_title AS a
    JOIN movie_keyword AS mk ON a.id = mk.movie_id
    JOIN keyword AS m ON mk.keyword_id = m.id
),
KeywordsCount AS (
    SELECT 
        movie_title,
        COUNT(keyword) AS keyword_count
    FROM MovieKeywords
    GROUP BY movie_title
),
ActorCount AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM MovieCast
    GROUP BY movie_title
)
SELECT 
    mc.movie_title,
    mc.production_year,
    ac.actor_count,
    kc.keyword_count
FROM MovieCast mc
JOIN ActorCount ac ON mc.movie_title = ac.movie_title
JOIN KeywordsCount kc ON mc.movie_title = kc.movie_title
ORDER BY mc.production_year DESC, mc.movie_title;
