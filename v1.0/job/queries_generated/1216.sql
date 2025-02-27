WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularKeywords AS (
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
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        pk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PopularKeywords pk ON rm.movie_id = pk.movie_id
    WHERE 
        rm.rank_by_cast <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(*)
     FROM movie_info mi
     WHERE mi.movie_id = tm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_count
FROM 
    TopMovies tm
ORDER BY 
    tm.cast_count DESC,
    tm.production_year DESC;
