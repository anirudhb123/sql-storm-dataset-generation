WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
),
PopularActors AS (
    SELECT 
        ci.movie_id,
        an.name AS actor_name,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id, an.name
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(DISTINCT pa.actor_name, ', ') AS top_actors
    FROM 
        RankedMovies rm
    JOIN 
        PopularActors pa ON rm.movie_id = pa.movie_id
    WHERE 
        rm.rn = 1
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    tm.title,
    tm.production_year,
    tm.top_actors,
    COUNT(mi.id) AS info_count,
    STRING_AGG(DISTINCT mi.info, '; ') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Box Office', 'Awards', 'Reviews'))
GROUP BY 
    tm.title, tm.production_year, tm.top_actors
ORDER BY 
    tm.production_year DESC;
