WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        ct.kind AS company_type, 
        COUNT(DISTINCT mc.company_id) AS total_companies,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title at 
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year, ct.kind
), RelevantActors AS (
    SELECT 
        ak.person_id, 
        ak.name, 
        ci.movie_id, 
        COUNT(DISTINCT ci.role_id) AS roles_played
    FROM 
        aka_name ak 
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL 
    GROUP BY 
        ak.person_id, ak.name, ci.movie_id
), HighRoleActors AS (
    SELECT 
        ra.person_id, 
        ra.name
    FROM 
        RelevantActors ra
    WHERE 
        ra.roles_played >= 3
)
SELECT 
    rm.title AS movie_title, 
    rm.production_year, 
    rm.total_companies, 
    ha.name AS actor_name
FROM 
    RankedMovies rm
LEFT JOIN 
    HighRoleActors ha ON ha.movie_id IN (SELECT movie_id FROM cast_info ci WHERE ci.movie_id = rm.id)
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.total_companies DESC, rm.production_year DESC;
