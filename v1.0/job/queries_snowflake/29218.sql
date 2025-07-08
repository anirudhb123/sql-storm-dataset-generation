
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword AS main_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_count,
        cd.actor_names,
        rm.main_keyword
    FROM 
        RankedMovies rm
    JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    WHERE 
        rm.keyword_rank = 1
)
SELECT 
    pm.title,
    pm.production_year,
    pm.actor_count,
    pm.actor_names,
    pm.main_keyword
FROM 
    PopularMovies pm
ORDER BY 
    pm.production_year DESC, 
    pm.actor_count DESC;
