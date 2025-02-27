WITH frequent_titles AS (
    SELECT 
        a.title,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.movie_id = c.movie_id
    GROUP BY 
        a.title
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
), 

person_info_aggregates AS (
    SELECT 
        pi.person_id,
        STRING_AGG(pi.info, ', ') AS info_details
    FROM 
        person_info pi
    WHERE 
        pi.info IS NOT NULL
    GROUP BY 
        pi.person_id
), 

company_titles AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), 

cast_rankings AS (
    SELECT 
        c.movie_id, 
        c.person_id, 
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rank
    FROM 
        cast_info c
), 

keyword_filtered AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword NOT LIKE '%unknown%' 
    GROUP BY 
        mk.movie_id
)

SELECT 
    t.title AS movie_title,
    ft.actor_count,
    ci.info_details,
    ct.companies,
    kf.keyword_count,
    RANK() OVER (ORDER BY ft.actor_count DESC) AS title_rank
FROM 
    frequent_titles ft
LEFT JOIN 
    title t ON t.title = ft.title
LEFT JOIN 
    person_info_aggregates ci ON ci.person_id IN (
        SELECT person_id 
        FROM cast_info 
        WHERE movie_id = t.id
    )
LEFT JOIN 
    company_titles ct ON ct.movie_id = t.id
LEFT JOIN 
    keyword_filtered kf ON kf.movie_id = t.id
WHERE 
    (t.production_year IS NULL OR t.production_year BETWEEN 2000 AND 2023)
    AND (ct.companies IS NOT NULL OR kf.keyword_count > 3)
ORDER BY 
    ft.actor_count DESC, title_rank;
