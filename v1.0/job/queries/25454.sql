WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS keywords,
        a.name AS actor_name,
        a.surname_pcode,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, c.name, k.keyword, a.name, a.surname_pcode
),
filter_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        company_name,
        keywords,
        actor_name,
        surname_pcode,
        num_companies,
        num_actors
    FROM 
        movie_details
    WHERE 
        num_companies > 1 AND num_actors > 5
)
SELECT 
    f.movie_id, 
    f.title, 
    f.production_year,
    f.company_name,
    STRING_AGG(DISTINCT f.keywords, ', ') AS combined_keywords,
    f.actor_name,
    f.surname_pcode,
    f.num_companies,
    f.num_actors
FROM 
    filter_movies f
GROUP BY 
    f.movie_id, f.title, f.production_year, f.company_name, f.actor_name, f.surname_pcode, f.num_companies, f.num_actors
ORDER BY 
    f.production_year DESC, 
    f.num_actors DESC;
