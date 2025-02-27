WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.company_id) AS company_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_cast_order,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.company_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsWithRoles AS (
    SELECT 
        ak.name AS actor_name, 
        rt.role AS role_name, 
        ci.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON rt.id = ci.role_id
    WHERE 
        ak.name IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    rm.company_count,
    rm.avg_cast_order,
    ak.actor_name,
    ak.role_name,
    ak.actor_rank,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsWithRoles ak ON rm.title_id = ak.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
WHERE 
    rm.rank <= 5 AND 
    (rm.company_count > 0 OR ak.actor_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.company_count DESC, ak.actor_rank;
