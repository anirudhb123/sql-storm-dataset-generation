WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        kt.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        t.production_year IS NOT NULL
),
actor_roles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, c.movie_id, r.role
),
company_info AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
person_awards AS (
    SELECT 
        pi.person_id,
        COUNT(pi.id) AS award_count
    FROM 
        person_info pi
    WHERE 
        pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'award')
    GROUP BY 
        pi.person_id
),
title_aggregate AS (
    SELECT 
        t.id AS title_id,
        COALESCE(SUM(a.role_count), 0) AS total_roles,
        COALESCE(MAX(pa.award_count), 0) AS max_awards
    FROM 
        ranked_titles t
    LEFT JOIN 
        actor_roles a ON t.title_id = a.movie_id
    LEFT JOIN 
        person_awards pa ON a.person_id = pa.person_id
    GROUP BY 
        t.id
)
SELECT 
    tt.title,
    tt.production_year,
    tt.total_roles,
    tt.max_awards,
    ci.company_name,
    ci.company_type,
    CASE  
        WHEN tt.total_roles > 10 THEN 'High Cast'
        WHEN tt.max_awards > 5 THEN 'Award Winning'
        ELSE 'Regular'
    END AS classification
FROM 
    title_aggregate tt
LEFT JOIN 
    company_info ci ON tt.title_id = ci.movie_id
WHERE 
    tt.production_year IS NOT NULL
ORDER BY 
    tt.production_year DESC, 
    tt.total_roles DESC, 
    tt.max_awards DESC
LIMIT 50;

-- This query returns a list of movie titles along with their production year, total role counts, and max awards received,
-- together with associated production companies, while classifying movies based on their attributes.
-- The use of CTEs helps in effectively organizing and simplifying the query into logical blocks.
