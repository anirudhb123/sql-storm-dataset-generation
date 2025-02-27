WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count,
        AVG(m.production_year) AS avg_production_year
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        aka_title m ON ci.movie_id = m.id
    GROUP BY 
        a.id, a.name
),
RankedMovies AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.company_name,
        md.keyword,
        md.keyword_rank,
        AD.name AS actor_name,
        AD.movie_count,
        AD.avg_production_year
    FROM 
        MovieDetails md
    JOIN 
        ActorDetails AD ON md.title_id IN (SELECT movie_id FROM cast_info WHERE person_id IN (SELECT id FROM aka_name WHERE name = AD.name))
)
SELECT 
    title,
    production_year,
    company_name,
    STRING_AGG(keyword, ', ') AS keywords,
    MAX(actor_name) AS first_actor,
    COUNT(DISTINCT actor_name) AS total_actors,
    AVG(avg_production_year) AS avg_movie_year
FROM 
    RankedMovies
WHERE 
    production_year > 2000
    AND keyword_rank = 1
GROUP BY 
    title, production_year, company_name
ORDER BY 
    total_actors DESC, production_year DESC;
