
WITH RECURSIVE RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        MAX(CASE WHEN ct.kind LIKE 'Distributor%' THEN 1 ELSE 0 END) AS has_distributor
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
ActorsWithRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS actor_role,
        COUNT(*) OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT a.actor_name) AS actor_count,
    COALESCE(COUNT(DISTINCT mc.movie_id), 0) AS company_count,
    COALESCE(LISTAGG(DISTINCT mk.keywords, '; '), 'No keywords') AS all_keywords,
    LISTAGG(DISTINCT ct.kind, ', ') AS company_types,
    CASE 
        WHEN COUNT(DISTINCT a.actor_name) > 5 THEN 'Popular'
        WHEN COUNT(DISTINCT a.actor_name) BETWEEN 3 AND 5 THEN 'Moderate'
        ELSE 'Niche' 
    END AS popularity_category,
    RANK() OVER (ORDER BY t.production_year DESC, COUNT(DISTINCT a.actor_name) DESC) AS popularity_rank
FROM 
    title t
LEFT JOIN 
    CompanyCounts mc ON t.id = mc.movie_id
LEFT JOIN 
    ActorsWithRoles a ON t.id = a.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
LEFT JOIN 
    MovieKeywords mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_companies comp ON t.id = comp.movie_id
LEFT JOIN 
    company_type ct ON comp.company_type_id = ct.id
WHERE 
    t.production_year > 2000 
    AND (mi.info IS NOT NULL OR mk.keywords IS NOT NULL)
GROUP BY 
    t.id, t.title, t.production_year
HAVING 
    COUNT(DISTINCT a.actor_name) >= 2
    AND COALESCE(SUM(mc.total_companies), 0) > 1
ORDER BY 
    t.production_year DESC, popularity_rank
LIMIT 50;
