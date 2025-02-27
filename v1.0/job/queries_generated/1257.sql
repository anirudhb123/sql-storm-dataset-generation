WITH RecursiveActorRoles AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        COUNT(ca.role_id) AS total_roles,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY COUNT(ca.role_id) DESC) AS role_rank
    FROM 
        cast_info ca
    GROUP BY 
        ca.person_id, ca.movie_id
),
TopActors AS (
    SELECT 
        a.id,
        ak.name,
        ra.total_roles
    FROM 
        aka_name ak
    JOIN 
        RecursiveActorRoles ra ON ak.person_id = ra.person_id
    WHERE 
        ra.role_rank = 1
        AND ak.name IS NOT NULL
),
MovieDetails AS (
    SELECT 
        at.title,
        at.production_year,
        mc.company_id,
        cn.name AS company_name,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mw ON at.id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    GROUP BY 
        at.id, mc.company_id, cn.name, at.title, at.production_year
)
SELECT 
    ta.name AS actor_name,
    md.title,
    md.production_year,
    COALESCE(md.company_name, 'Independent') AS production_company,
    md.keywords
FROM 
    TopActors ta
JOIN 
    MovieDetails md ON ta.total_roles > 5
LEFT JOIN 
    complete_cast cc ON md.title = cc.movie_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ta.total_roles DESC, md.production_year ASC;
