WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS company_type,
        a.name AS actor_name,
        p.gender
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND c.kind LIKE '%Production%'
),
ActorCount AS (
    SELECT 
        title_id,
        COUNT(actor_name) AS actor_count
    FROM 
        MovieDetails
    GROUP BY 
        title_id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.company_type,
    ac.actor_count,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords
FROM 
    MovieDetails md
JOIN 
    ActorCount ac ON md.title_id = ac.title_id
JOIN 
    movie_keyword mk ON md.title_id = mk.movie_id
WHERE 
    md.gender = 'F'
GROUP BY 
    md.title, md.production_year, md.keyword, md.company_type, ac.actor_count
ORDER BY 
    md.production_year DESC, ac.actor_count DESC;
