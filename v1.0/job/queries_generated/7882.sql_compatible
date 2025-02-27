
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT CAST(pi.info AS VARCHAR) || ' (' || rt.role || ')', ', ') AS actor_roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        person_info pi ON ci.person_id = pi.person_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.actor_count
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    COALESCE(md.keywords, 'No Keywords') AS keywords,
    COALESCE(md.actor_roles, 'No Actors') AS actor_roles
FROM 
    MovieDetails md
WHERE 
    md.actor_count > 0
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
