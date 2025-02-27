WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        rt.role AS role_type
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, rt.role
),
actor_info AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        GROUP_CONCAT(DISTINCT mk.keyword) AS actor_keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id
),
genre_info AS (
    SELECT 
        kt.kind AS genre,
        COUNT(DISTINCT t.id) AS movie_count
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    GROUP BY 
        kt.kind
)
SELECT 
    md.title AS movie_title,
    md.production_year,
    md.companies,
    ai.name AS actor_name,
    ai.movie_count AS actor_movie_count,
    ai.actor_keywords,
    gi.genre,
    gi.movie_count AS genre_movie_count
FROM 
    movie_details md
JOIN 
    actor_info ai ON md.title_id IN (
        SELECT 
            ci.movie_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.person_role_id = ai.actor_id
    )
JOIN 
    genre_info gi ON gi.movie_count = (
        SELECT 
            COUNT(*) 
        FROM 
            title t 
        WHERE 
            t.kind_id = gi.genre
    )
ORDER BY 
    md.production_year DESC, 
    movie_title;
