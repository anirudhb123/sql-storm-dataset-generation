WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        t.id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        ak.name,
        ak.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT t.title, ', ') AS movies_list
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    GROUP BY 
        ak.id, ak.name, ak.person_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS rn
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ai.name AS actor_name,
    ai.total_movies,
    ai.movies_list,
    cd.company_name,
    cd.company_type,
    COUNT(DISTINCT cd.company_name) OVER (PARTITION BY mh.movie_id) AS num_companies,
    CASE 
        WHEN cd.rn IS NULL THEN 'No Company'
        ELSE cd.company_name 
    END AS effective_company_name
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorInfo ai ON ai.actor_id IN (
        SELECT 
            DISTINCT ci.person_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.movie_id = mh.movie_id
    )
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = mh.movie_id
ORDER BY 
    mh.production_year DESC, mh.title;
