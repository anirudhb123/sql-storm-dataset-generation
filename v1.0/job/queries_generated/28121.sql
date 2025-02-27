WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS movie_kind,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year IS NOT NULL
),

HighestRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        movie_kind
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),

CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),

MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        c.total_cast,
        c.actor_names,
        k.keyword AS keywords
    FROM 
        HighestRankedMovies m
    JOIN 
        CastDetails c ON m.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)

SELECT 
    mi.movie_title,
    mi.production_year,
    mi.total_cast,
    mi.actor_names,
    STRING_AGG(DISTINCT mi.keywords, ', ') AS movie_keywords
FROM 
    MovieInfo mi
GROUP BY 
    mi.movie_title, mi.production_year, mi.total_cast, mi.actor_names
ORDER BY 
    mi.production_year DESC, 
    mi.movie_title;
