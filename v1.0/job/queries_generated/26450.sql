WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_members_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name an ON c.person_id = an.person_id
    WHERE 
        m.production_year >= 2000  -- Filter for movies from the year 2000 onwards
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5  -- Only include movies with more than 5 cast members
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
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Awards' THEN mi.info END) AS awards,
        MAX(CASE WHEN it.info = 'Box Office' THEN mi.info END) AS box_office
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.cast_members_count,
    rm.actor_names,
    mk.keywords,
    mi.awards,
    mi.box_office
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 10  -- Get top 10 movies by cast members count
ORDER BY 
    rm.cast_members_count DESC;
