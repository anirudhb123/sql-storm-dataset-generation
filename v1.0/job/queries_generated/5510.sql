WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    WHERE t.production_year >= 2000
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        c.movie_id
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
),
CompleteInfo AS (
    SELECT 
        md.title,
        md.production_year,
        md.keyword,
        ad.actor_name,
        ad.person_id,
        COUNT(DISTINCT c.id) AS cast_count
    FROM MovieDetails md
    JOIN ActorDetails ad ON md.title_id = ad.movie_id
    LEFT JOIN complete_cast c ON md.title_id = c.movie_id 
    GROUP BY md.title, md.production_year, md.keyword, ad.actor_name, ad.person_id
)
SELECT 
    title,
    production_year,
    keyword,
    actor_name,
    cast_count
FROM CompleteInfo
WHERE cast_count > 2
ORDER BY production_year DESC, title;
