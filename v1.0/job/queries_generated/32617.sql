WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 

    UNION ALL 

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.depth + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy h ON m.episode_of_id = h.movie_id
),
ActorAwards AS (
    SELECT 
        p.person_id,
        COUNT(DISTINCT a.id) AS awards_count
    FROM 
        person_info p
    JOIN 
        cast_info c ON p.person_id = c.person_id
    JOIN 
        aka_name a ON a.person_id = p.person_id
    WHERE 
        p.info_type_id = (SELECT id FROM info_type WHERE info = 'award')
    GROUP BY 
        p.person_id
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MoviesWithActors AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(ak.awards_count, 0) AS awards_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        cast_info c ON c.movie_id = m.movie_id
    LEFT JOIN 
        ActorAwards ak ON c.person_id = ak.person_id
    LEFT JOIN 
        MovieKeywords mk ON m.movie_id = mk.movie_id
)
SELECT 
    movie.title,
    movie.production_year,
    movie.awards_count,
    movie.keywords,
    COUNT(c.id) OVER (PARTITION BY movie.movie_id) AS actor_count,
    ROW_NUMBER() OVER (ORDER BY movie.awards_count DESC, movie.title) AS rank
FROM 
    MoviesWithActors movie
LEFT JOIN 
    complete_cast cc ON movie.movie_id = cc.movie_id
WHERE 
    movie.production_year IS NOT NULL
    AND (movie.keywords IS NOT NULL OR movie.keywords != 'No keywords')
ORDER BY 
    movie.awards_count DESC, 
    movie.title;
