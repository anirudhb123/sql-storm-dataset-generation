WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
TopCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT m.info) AS infos,
        GROUP_CONCAT(DISTINCT CASE WHEN it.info = 'Genre' THEN m.info END) AS genres,
        GROUP_CONCAT(DISTINCT CASE WHEN it.info = 'Synopsis' THEN m.info END) AS synopsis
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.movie_keyword,
    tc.actor_name,
    tc.role,
    mi.infos,
    mi.genres,
    mi.synopsis
FROM 
    RankedMovies rm
LEFT JOIN 
    TopCast tc ON rm.movie_id = tc.movie_id AND tc.actor_rank <= 3
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
