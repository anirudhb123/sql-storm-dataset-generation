WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index,
        p.gender AS actor_gender,
        COUNT(DISTINCT mc.company_id) AS production_company_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        name p ON ak.person_id = p.imdb_id
    GROUP BY 
        t.title, t.production_year, ak.name, ak.imdb_index, p.gender
)

SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.actor_index,
    md.actor_gender,
    md.production_company_count,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000 AND 
    md.actor_gender = 'M'
ORDER BY 
    md.production_year DESC, md.actor_name;

