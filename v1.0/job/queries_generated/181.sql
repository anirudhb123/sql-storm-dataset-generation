WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT CONCAT(mk.keyword, ' (', mk.id, ')'), '; ') AS keywords,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        movie_keyword mk 
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mi.keywords,
        mi.info_count
    FROM 
        RankedMovies rm
    JOIN 
        MovieInfo mi ON rm.movie_id = mi.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.keywords, 'No Keywords') AS keywords,
    COALESCE(tm.info_count, 0) AS info_count,
    (SELECT 
         GROUP_CONCAT(CONCAT(a.name, ' (ID: ', a.id, ')')) 
     FROM 
         aka_name a 
     JOIN 
         cast_info ci ON a.person_id = ci.person_id 
     WHERE 
         ci.movie_id = tm.movie_id) AS cast_names
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.info_count DESC;
