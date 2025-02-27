WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(c.person_id) AS actor_count,
        AVG(rg.rating) AS average_rating,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            AVG(rating) AS rating
         FROM 
            movie_info mi
         WHERE 
            mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
         GROUP BY movie_id) rg ON m.movie_id = rg.movie_id
    GROUP BY 
        m.id, m.title
),
FamousActors AS (
    SELECT 
        a.person_id, 
        MAX(a.name) AS actor_name
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
    HAVING 
        COUNT(c.movie_id) > 5
),
MovieTitles AS (
    SELECT 
        m.title, 
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rm.title,
    rm.actor_count,
    COALESCE(fa.actor_name, 'Unknown Actor') AS lead_actor,
    mt.keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    FamousActors fa ON rm.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = fa.person_id ORDER BY nr_order ASC LIMIT 1)
LEFT JOIN 
    MovieTitles mt ON rm.movie_id = mt.movie_id
WHERE 
    rm.year_rank <= 3 
    AND rm.actor_count IS NOT NULL 
    AND (rm.average_rating IS NULL OR rm.average_rating > 7.5)
ORDER BY 
    rm.actor_count DESC, 
    rm.title;
