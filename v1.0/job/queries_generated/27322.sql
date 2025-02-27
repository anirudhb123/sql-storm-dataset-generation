WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
PopularActors AS (
    SELECT 
        ai.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    GROUP BY 
        ai.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT pc.kind ORDER BY pc.kind) AS production_companies
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type pc ON mc.company_type_id = pc.id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    rt.title,
    rt.production_year,
    rt.keyword,
    pa.actor_name,
    md.production_companies
FROM 
    RankedTitles rt
JOIN 
    PopularActors pa ON rt.title_id IN (SELECT ci.movie_id FROM cast_info ci JOIN aka_name an ON ci.person_id = an.person_id WHERE an.name = pa.actor_name)
JOIN 
    MovieDetails md ON rt.title = md.title AND rt.production_year = md.production_year
WHERE 
    rt.keyword_rank = 1
ORDER BY 
    rt.production_year DESC, rt.title;
This SQL query generates a comprehensive overview of popular movies, showing their keyword associations and the top actors involved in them, provided the actors have appeared in more than five movies. It also displays the production companies associated with each movie, making it suitable for benchmarking string processing in complex SQL scenarios.
