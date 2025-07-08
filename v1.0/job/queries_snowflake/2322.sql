
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    GROUP BY 
        ci.movie_id
),
MovieKeywordInfo AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(ar.actor_count, 0) AS total_actors,
    ar.actor_names,
    COALESCE(mki.keywords, 'No keywords') AS keywords_list
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MovieKeywordInfo mki ON rm.movie_id = mki.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, total_actors DESC;
