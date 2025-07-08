
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS total_cast, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year, a.id
),
BestMovies AS (
    SELECT 
        rm.movie_title, 
        rm.production_year, 
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        bm.movie_title, 
        bm.production_year, 
        bm.total_cast, 
        COALESCE(mk.keywords, 'No keywords') AS keywords, 
        COALESCE(mi.info, 'No info available') AS additional_info
    FROM 
        BestMovies bm
    LEFT JOIN 
        MovieKeywords mk ON bm.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        movie_info mi ON (SELECT id FROM aka_title WHERE title = bm.movie_title LIMIT 1) = mi.movie_id
    ORDER BY 
        bm.production_year DESC, bm.total_cast DESC
)
SELECT 
    dmi.movie_title, 
    dmi.production_year, 
    dmi.total_cast, 
    dmi.keywords, 
    dmi.additional_info,
    CASE 
        WHEN dmi.total_cast > 10 THEN 'Popular'
        ELSE 'Less popular'
    END AS popularity_status
FROM 
    DetailedMovieInfo dmi
WHERE 
    dmi.production_year >= 2000
ORDER BY 
    dmi.total_cast DESC, dmi.production_year DESC;
