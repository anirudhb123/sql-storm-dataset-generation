
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        mc.movie_id,
        ci.person_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY mc.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        complete_cast mc
    JOIN 
        cast_info ci ON mc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COUNT(DISTINCT mc.person_id) AS total_actors,
    MAX(mc.actor_name) AS lead_actor,
    AVG(COALESCE(NULLIF(mc.actor_rank, 0), NULL)) AS avg_actor_rank,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    rm.rank_within_year <= 5 AND 
    rm.production_year > 2000
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
HAVING 
    COUNT(DISTINCT mc.person_id) > 0
ORDER BY 
    rm.production_year DESC, total_actors DESC;
