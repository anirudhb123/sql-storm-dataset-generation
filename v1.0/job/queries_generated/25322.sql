WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS title,
        m.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id
), ActorDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT md.info, ', ') AS info_details
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    JOIN 
        person_info md ON p.person_id = md.person_id
    GROUP BY 
        p.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    md.total_actors,
    ad.person_id,
    ad.name AS actor_name,
    ad.movie_count,
    ad.info_details
FROM 
    MovieDetails md
JOIN 
    ActorDetails ad ON ad.movie_count > 0
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, 
    md.title, 
    ad.name;
