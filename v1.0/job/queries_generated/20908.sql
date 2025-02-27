WITH recursive CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
TitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COALESCE(t.production_year, 'Unknown') AS production_year,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(t.title, 'Unknown') ORDER BY t.production_year DESC) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL AND t.production_year > 2000
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        ARRAY_AGG(DISTINCT r.role) AS roles,
        COUNT(DISTINCT ak.name) AS actor_count
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        c.movie_id
),
NullCheck AS (
    SELECT 
        title_info.title_id,
        title_info.title,
        COALESCE(ar.actor_count, 0) AS actor_count,
        COALESCE(cc.company_count, 0) AS company_count
    FROM 
        TitleInfo title_info
    LEFT JOIN 
        ActorRoles ar ON title_info.title_id = ar.movie_id
    LEFT JOIN 
        CompanyMovieCounts cc ON title_info.title_id = cc.movie_id
)
SELECT 
    nc.title,
    TRIM(nc.title) || ' (' || COALESCE(NULLIF(nc.production_year, 'Unknown'), 'N/A') || ')' AS formatted_title,
    nc.actor_count,
    nc.company_count,
    CASE 
        WHEN nc.actor_count > 5 AND nc.company_count > 0 THEN 'Blockbuster'
        WHEN nc.actor_count BETWEEN 1 AND 5 THEN 'Indie'
        ELSE 'Unknown'
    END AS classification,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords
FROM 
    NullCheck nc
LEFT JOIN 
    TitleInfo ti ON nc.title_id = ti.title_id
LEFT JOIN 
    movie_keyword mk ON ti.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    nc.actor_count IS NOT NULL 
GROUP BY 
    nc.title, nc.production_year
ORDER BY 
    actor_count DESC, company_count ASC NULLS LAST;
