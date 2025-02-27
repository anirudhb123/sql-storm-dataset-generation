WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS total_movies,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
),
movie_keyword_info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_films AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, '; ') AS company_names,
        COUNT(mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ai.name AS actor_name,
    ai.total_movies,
    ai.null_notes_count,
    mki.keywords,
    cfi.company_names,
    cfi.total_companies
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
LEFT JOIN 
    actor_info ai ON ci.person_id = ai.person_id
LEFT JOIN 
    movie_keyword_info mki ON rt.title_id = mki.movie_id
LEFT JOIN 
    company_films cfi ON rt.title_id = cfi.movie_id
WHERE 
    rt.production_year = (
        SELECT 
            MAX(production_year)
        FROM 
            aka_title
        WHERE 
            production_year IS NOT NULL
    )
AND 
    (ai.total_movies > 5 OR ai.null_notes_count > 0)
ORDER BY 
    rt.production_year DESC, rt.title ASC
OFFSET 
    10 ROWS FETCH NEXT 10 ROWS ONLY;
