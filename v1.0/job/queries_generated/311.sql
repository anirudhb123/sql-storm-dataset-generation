WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY t.id) AS avg_order,
        RANK() OVER (ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
DetailedMovieInfo AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(mi.info, 'No Info') AS movie_details,
        GROUP_CONCAT(COALESCE(k.keyword, 'No Keyword')) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_id
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.movie_details,
    dmi.keywords,
    CASE 
        WHEN dmi.production_year > 2015 THEN 'Recent'
        ELSE 'Classic'
    END AS movie_category,
    (SELECT 
        COUNT(*) 
     FROM 
        cast_info ci 
     WHERE 
        ci.movie_id = dmi.movie_id 
        AND ci.note IS NOT NULL) AS noted_cast_count
FROM 
    DetailedMovieInfo dmi
ORDER BY 
    dmi.production_year DESC, 
    dmi.title ASC;
