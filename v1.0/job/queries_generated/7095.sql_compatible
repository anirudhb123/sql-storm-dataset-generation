
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        STRING_AGG(DISTINCT c.name, ',') AS companies
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    GROUP BY t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY a.person_id, a.name
),
TopActors AS (
    SELECT 
        ad.person_id, 
        ad.name, 
        ad.movie_count
    FROM ActorDetails ad
    WHERE ad.movie_count > 5
    ORDER BY ad.movie_count DESC
    LIMIT 10
)
SELECT 
    md.title, 
    md.production_year, 
    ta.name AS top_actor, 
    ta.movie_count
FROM MovieDetails md
JOIN cast_info ci ON md.movie_id = ci.movie_id
JOIN TopActors ta ON ci.person_id = ta.person_id
ORDER BY md.production_year DESC, ta.movie_count DESC;
