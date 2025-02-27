WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(mi.info) FILTER (WHERE mi.info IS NOT NULL) AS info_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.actor_names, mk.keywords
),
FinalOutput AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        cast_count,
        actor_names,
        keywords,
        info_count,
        RANK() OVER (ORDER BY production_year DESC, cast_count DESC) AS rank
    FROM 
        MoviesWithInfo
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    actor_names,
    keywords,
    info_count,
    rank
FROM 
    FinalOutput
WHERE 
    cast_count > 5  -- Focus on movies with more than 5 cast members
ORDER BY 
    rank;
