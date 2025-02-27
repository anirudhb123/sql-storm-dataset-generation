WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year ORDER BY t.production_year DESC) AS rank_by_year,
        COUNT(*) OVER () AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        CASE 
            WHEN rm.rank_by_year <= (SELECT COUNT(*) FROM RankedMovies) / 2 THEN 'Top Half'
            ELSE 'Bottom Half'
        END AS movie_rank_category
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_year <= 100
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        f.movie_id,
        f.title,
        f.movie_rank_category,
        cd.actors,
        cd.actor_count,
        COALESCE(mi.info, 'No Info Available') AS additional_info
    FROM 
        FilteredMovies f
    LEFT JOIN 
        CastDetails cd ON f.movie_id = cd.movie_id
    LEFT JOIN 
        movie_info mi ON f.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1)
)
SELECT 
    m.title,
    m.production_year,
    m.movie_rank_category,
    m.actors,
    m.actor_count,
    CASE 
        WHEN m.actor_count > 10 THEN 'A Large Cast'
        WHEN m.actor_count IN (NULL, 0) THEN 'No Cast Found'
        ELSE 'A Small Cast'
    END AS cast_quality,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    MovieInfo m
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year >= 2000
GROUP BY 
    m.movie_id, m.title, m.production_year, m.movie_rank_category, m.actors, m.actor_count
HAVING 
    COUNT(DISTINCT k.keyword) >= 1 OR m.actors IS NOT NULL
ORDER BY 
    m.production_year DESC, m.actor_count DESC, m.title;
