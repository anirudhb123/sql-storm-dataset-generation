
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rank,
        COUNT(*) OVER (PARTITION BY m.production_year) AS total_movies
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        p.gender,
        COALESCE(MAX(c.nr_order), 0) AS max_order,
        COUNT(DISTINCT a.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        name p ON a.person_id = p.imdb_id
    GROUP BY 
        c.movie_id, a.name, p.gender
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    cd.actor_name,
    cd.gender,
    cd.max_order,
    cd.actor_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN cd.actor_count > 5 THEN 'Ensemble'
        WHEN cd.actor_count BETWEEN 3 AND 5 THEN 'Small Group'
        ELSE 'Solo'
    END AS cast_size_category,
    CASE 
        WHEN rm.rank = 1 AND rm.total_movies > 10 THEN 'Top Release'
        WHEN rm.rank = 1 AND rm.total_movies <= 10 THEN 'Indie Feature'
        ELSE 'Other'
    END AS movie_classification
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.movie_id;
