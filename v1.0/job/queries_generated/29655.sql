WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        p.name AS person_name,
        r.role AS person_role
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name p ON ci.person_id = p.person_id
    JOIN
        role_type r ON ci.role_id = r.id
    WHERE
        t.production_year >= 2000 AND 
        k.keyword LIKE '%Action%'
),
summary AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        COUNT(DISTINCT md.person_name) AS actor_count,
        COUNT(DISTINCT md.keyword) AS keyword_count,
        STRING_AGG(DISTINCT md.person_name, ', ') AS actor_names,
        STRING_AGG(DISTINCT md.keyword, ', ') AS keywords
    FROM 
        movie_data md
    GROUP BY 
        md.movie_id, md.title, md.production_year
)
SELECT 
    s.movie_id,
    s.title,
    s.production_year,
    s.actor_count,
    s.keyword_count,
    s.actor_names,
    s.keywords
FROM 
    summary s
ORDER BY 
    s.production_year DESC, 
    s.actor_count DESC;
