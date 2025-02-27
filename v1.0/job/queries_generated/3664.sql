WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actors_info AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT at.title, ', ') AS titles
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title at ON ci.movie_id = at.id
    GROUP BY 
        a.person_id, a.name
),
company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title AS movie_title,
        rm.production_year,
        COALESCE(ki.keyword_total, 0) AS keyword_count,
        ci.company_name,
        ci.company_type
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_count ki ON rm.movie_id = ki.movie_id
    LEFT JOIN 
        company_info ci ON rm.movie_id = ci.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.keyword_count,
    ai.name AS actor_name,
    ai.movie_count,
    ai.titles,
    md.company_name,
    md.company_type
FROM 
    movie_details md
INNER JOIN 
    actors_info ai ON EXISTS (
        SELECT 1
        FROM cast_info ci
        WHERE ci.movie_id = md.movie_id AND ci.person_id = ai.person_id
    )
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC, 
    ai.movie_count DESC;
