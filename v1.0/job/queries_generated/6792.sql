WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        r.role AS actor_role,
        c.kind AS company_type
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id AND ci.id = cc.subject_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type c ON c.id = mc.company_type_id
    JOIN 
        role_type r ON r.id = ci.role_id
    WHERE 
        t.production_year >= 2000
),
KeywordCounts AS (
    SELECT 
        md.movie_title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        MovieDetails md
    JOIN 
        movie_keyword mk ON md.movie_title = (SELECT title FROM title WHERE id = mk.movie_id)
    GROUP BY 
        md.movie_title
)
SELECT 
    d.movie_title,
    d.production_year,
    d.actor_name,
    d.actor_role,
    d.company_type,
    kc.keyword_count
FROM 
    MovieDetails d
JOIN 
    KeywordCounts kc ON d.movie_title = kc.movie_title
ORDER BY 
    d.production_year DESC, 
    d.movie_title;
