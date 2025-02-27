WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS top_actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithRating AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.top_actors,
        rm.keywords,
        AVG(r.rating) AS average_rating
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        (SELECT 
             movie_id, 
             CAST(SUBSTRING(info FROM 'Rating: (\d+\.\d+)') AS FLOAT) AS rating
         FROM 
             movie_info 
         WHERE 
             info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
        ) r ON rm.movie_id = r.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.top_actors, rm.keywords
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.cast_count,
    mw.top_actors,
    mw.keywords,
    COALESCE(mw.average_rating, 0) AS average_rating
FROM 
    MoviesWithRating mw
ORDER BY 
    mw.production_year DESC, 
    mw.cast_count DESC, 
    mw.average_rating DESC
LIMIT 10;
