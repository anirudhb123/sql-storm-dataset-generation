WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        co.kind AS company_type
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN company_type co ON mc.company_type_id = co.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, co.kind
),

ActorCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    GROUP BY a.person_id
    HAVING COUNT(DISTINCT c.movie_id) > 5
),

CombinedDetails AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        ac.total_movies,
        ac.actor_names
    FROM MovieDetails md
    JOIN ActorCounts ac ON md.movie_id = ac.person_id
)

SELECT 
    movie_id, 
    title, 
    production_year,
    keywords,
    total_movies,
    actor_names
FROM CombinedDetails
ORDER BY production_year DESC, total_movies DESC;
