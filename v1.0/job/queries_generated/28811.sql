WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.person_role_id) AS role_ids,
        GROUP_CONCAT(DISTINCT a.name) AS actor_names
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        mc.note IS NULL  -- Consider only companies without notes
        AND cn.country_code = 'USA'  -- Limit to USA companies
    GROUP BY 
        t.id, t.title, t.production_year
),

KeywordedMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        k.keyword AS movie_keyword
    FROM 
        MovieDetails md
    JOIN 
        movie_keyword mk ON mk.movie_id = md.movie_title
    JOIN 
        keyword k ON mk.keyword_id = k.id
)

SELECT 
    km.movie_title,
    km.production_year,
    km.movie_keyword,
    COUNT(DISTINCT km.movie_keyword) AS total_keywords,
    STRING_AGG(DISTINCT ka.actor_names, ', ') AS all_actors
FROM 
    KeywordedMovies km
JOIN 
    MovieDetails md ON km.movie_title = md.movie_title
GROUP BY 
    km.movie_title, km.production_year, km.movie_keyword
ORDER BY 
    km.production_year DESC, total_keywords DESC;
