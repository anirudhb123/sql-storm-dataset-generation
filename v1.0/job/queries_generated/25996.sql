WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        GROUP_CONCAT(DISTINCT c.role_id) AS roles,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM title t
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY t.id, t.title, t.production_year
),

ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        a.gender,
        GROUP_CONCAT(DISTINCT ci.movie_id) AS movies,
        COUNT(DISTINCT ci.movie_id) AS movie_count 
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY a.id, a.name, a.gender
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT cn.id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    ad.actor_id,
    ad.name AS actor_name,
    ad.gender,
    ad.movie_count AS total_movies_starred,
    cd.companies AS production_companies,
    cd.company_count AS total_companies,
    md.roles AS character_roles,
    md.keywords AS movie_keywords
FROM MovieDetails md
JOIN ActorDetails ad ON md.movie_id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = ad.actor_id)
JOIN CompanyDetails cd ON md.movie_id = cd.movie_id
WHERE md.production_year >= 2000
ORDER BY md.production_year DESC, ad.name;

This query generates a comprehensive overview of movies from the year 2000 onward along with their associated actors and production companies. It gathers detailed string information, aggregates roles and keywords, and enables performance benchmarking in string processing through the variety of Joins and aggregations used.
