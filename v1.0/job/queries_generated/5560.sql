WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY t.id
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        t.production_year,
        t.title,
        ci.role_id,
        r.role,
        COUNT(DISTINCT t.id) AS movies_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY a.id, a.name, t.production_year, t.title, ci.role_id, r.role
    HAVING COUNT(DISTINCT t.id) > 1
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    ad.actor_id,
    ad.name AS actor_name,
    ad.role,
    ad.movies_count,
    md.companies
FROM MovieDetails md
JOIN ActorDetails ad ON md.production_year = ad.production_year
ORDER BY md.production_year DESC, ad.movies_count DESC;
