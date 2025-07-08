
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY RANDOM()) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.id AS actor_id,
        c.nr_order,
        r.role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
KeywordSummary AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.nr_order,
    ks.keywords
FROM 
    RankedMovies rm
JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
JOIN 
    KeywordSummary ks ON rm.movie_id = ks.movie_id
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, 
    cd.nr_order;
