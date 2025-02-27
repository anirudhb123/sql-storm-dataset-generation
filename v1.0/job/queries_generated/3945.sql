WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TopActors AS (
    SELECT 
        ak.name,
        ak.person_id,
        COALESCE(CAST(AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS FLOAT), 0) AS avg_order
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ak.person_id
    HAVING 
        COUNT(ci.movie_id) > 1
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,  
        rm.title, 
        rm.production_year, 
        ac.actor_count, 
        COALESCE(ta.avg_order, 0) AS avg_actor_order
    FROM 
        RankedMovies rm
    JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        TopActors ta ON ac.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ta.person_id LIMIT 1)
    WHERE 
        ac.actor_count > 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.avg_actor_order,
    STRING_AGG(DISTINCT CONCAT(cn.name, ' (', ct.kind, ')'), ', ') AS companies
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    fm.title, fm.production_year, fm.actor_count, fm.avg_actor_order
ORDER BY 
    fm.production_year DESC, 
    fm.actor_count DESC, 
    fm.title;
