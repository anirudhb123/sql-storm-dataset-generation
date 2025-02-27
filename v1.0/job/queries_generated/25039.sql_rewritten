WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        rt.role AS person_role,
        a.name AS actor_name,
        p.info AS person_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND c.country_code = 'USA'
        AND rt.role IN ('Actor', 'Actress')
),
KeywordStats AS (
    SELECT 
        md.movie_title,
        COUNT(mk.id) AS keyword_count,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        MovieDetails md
    JOIN 
        movie_keyword mk ON md.movie_title = (SELECT title FROM title WHERE id = mk.movie_id)
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        md.movie_title
),
FinalOutput AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.company_name,
        md.person_role,
        md.actor_name,
        md.person_info,
        ks.keyword_count,
        ks.keywords_list
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordStats ks ON md.movie_title = ks.movie_title
    ORDER BY 
        md.production_year DESC, 
        md.movie_title ASC
)
SELECT *
FROM 
    FinalOutput
LIMIT 100;