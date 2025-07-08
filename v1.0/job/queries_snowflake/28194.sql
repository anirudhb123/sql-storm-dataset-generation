WITH RankedMovies AS (
    SELECT 
        DISTINCT t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
),
ActorDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        p.info AS personal_info,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY p.info_type_id) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        p.info_type_id IN (1, 2, 3) 
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keyword,
    ad.actor_name,
    ad.personal_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.movie_id = ad.movie_id AND ad.actor_rank = 1
WHERE 
    rm.rank_year = 1 
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;