WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY at.id) AS actor_count,
        AVG(COALESCE(CAST(mi.info AS FLOAT), 0)) OVER (PARTITION BY at.id) AS avg_rating
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        at.production_year >= 2000
),
HighRatedMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actor_count,
        avg_rating
    FROM 
        RankedMovies
    WHERE 
        avg_rating > 7.5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    hm.movie_id,
    hm.title,
    hm.production_year,
    hm.actor_count,
    mk.keywords
FROM 
    HighRatedMovies hm
LEFT JOIN 
    MovieKeywords mk ON hm.movie_id = mk.movie_id
ORDER BY 
    hm.production_year DESC, 
    hm.actor_count DESC;
