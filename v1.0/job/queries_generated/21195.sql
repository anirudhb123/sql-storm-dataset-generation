WITH recursive cte_movie_info AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ki.id) AS keyword_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year >= 2000
),
actor_roles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role,
        ci.note AS role_note,
        COALESCE(ci.nr_order, 0) AS order_num
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
movies_with_companies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mc.company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id, mc.company_id, cn.name, ct.kind
),
combined_info AS (
    SELECT 
        cte.movie_id,
        cte.title,
        cte.production_year,
        string_agg(DISTINCT k.keyword, ', ') AS keywords,
        coalesce(array_agg(DISTINCT ar.actor_name) FILTER (WHERE ar.role IS NOT NULL), '{}'::text[]) AS actors,
        coalesce(array_agg(DISTINCT mc.company_name) FILTER (WHERE mc.company_name IS NOT NULL), '{}'::text[]) AS companies
    FROM 
        cte_movie_info cte
    LEFT JOIN 
        actor_roles ar ON cte.movie_id = ar.movie_id
    LEFT JOIN 
        movies_with_companies mc ON cte.movie_id = mc.movie_id
    GROUP BY 
        cte.movie_id, cte.title, cte.production_year
)
SELECT 
    c.movie_id,
    c.title,
    c.production_year,
    c.keywords,
    c.actors,
    c.companies,
    CASE 
        WHEN c.production_year IS NULL THEN 'Year Unknown' 
        WHEN c.actors = '{}' THEN 'No Actors Listed' 
        ELSE 'Available' 
    END AS status,
    (SELECT COUNT(*) FROM info_type it WHERE it.id NOT IN (SELECT person_info.info_type_id FROM person_info WHERE person_id IN (SELECT DISTINCT person_id FROM cast_info))) AS orphan_info_count
FROM 
    combined_info c
WHERE 
    (c.keywords IS NOT NULL AND c.production_year BETWEEN 2000 AND 2023)
    OR (c.actors IS NOT NULL AND c.companies IS NOT NULL)
ORDER BY 
    c.production_year DESC, c.movie_id ASC
LIMIT 100 OFFSET 10;
