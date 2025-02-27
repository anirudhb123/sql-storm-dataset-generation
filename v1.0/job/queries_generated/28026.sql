WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.imdb_index,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        n.name AS actor_name,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY n.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    WHERE 
        ci.person_role_id = (SELECT id FROM role_type WHERE role = 'actor')
),
CombinedData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        fc.actor_name,
        fc.nr_order
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FilteredCast fc ON rm.movie_id = fc.movie_id
    WHERE 
        rm.rn <= 5
)
SELECT 
    movie_id,
    title,
    production_year,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT actor_name ORDER BY fc.nr_order) AS cast 
FROM 
    CombinedData
GROUP BY 
    movie_id, title, production_year
ORDER BY 
    production_year DESC, movie_id;
