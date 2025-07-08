WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS num_movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.person_id, a.name
),
film_industry AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        c.country_code,
        ct.kind AS company_type,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        mc.movie_id, c.name, c.country_code, ct.kind
)
SELECT 
    rt.title,
    rt.production_year,
    ad.name AS actor_name,
    ad.num_movies,
    fi.company_name,
    fi.country_code,
    fi.company_type,
    fi.keyword_count
FROM 
    ranked_titles rt
JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
JOIN 
    actor_details ad ON ci.person_id = ad.person_id
LEFT JOIN 
    film_industry fi ON rt.title_id = fi.movie_id
WHERE 
    rt.title_rank <= 5 
    AND (fi.company_name IS NULL OR fi.country_code = 'USA')
ORDER BY 
    rt.production_year DESC, ad.num_movies DESC;
