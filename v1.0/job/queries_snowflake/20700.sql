
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
actor_titles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(*) AS number_of_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies,
        COUNT(DISTINCT co.country_code) AS unique_countries
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
keyword_data AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tt.title_id,
    tt.title,
    tt.production_year,
    at.actor_name,
    at.number_of_roles,
    mci.companies,
    mci.unique_countries,
    kd.keywords,
    CASE 
        WHEN tt.title_rank = 1 THEN 'First in Year'
        ELSE 'Other Title'
    END AS title_category
FROM 
    ranked_titles tt
LEFT JOIN 
    actor_titles at ON tt.title_id = at.movie_id
LEFT JOIN 
    movie_company_info mci ON tt.title_id = mci.movie_id
LEFT JOIN 
    keyword_data kd ON tt.title_id = kd.movie_id
WHERE 
    tt.production_year >= 2000
GROUP BY 
    tt.title_id,
    tt.title,
    tt.production_year,
    at.actor_name,
    at.number_of_roles,
    mci.companies,
    mci.unique_countries,
    kd.keywords,
    tt.title_rank
ORDER BY 
    tt.production_year DESC, 
    tt.title_rank,
    at.number_of_roles DESC;
