WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
), 
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.info,
        it.info AS info_type
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
), 
QualifiedMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        mi.info AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieInfo mi ON rm.title = mi.info 
    WHERE 
        rm.rank <= 5
)
SELECT 
    Q.title,
    Q.production_year,
    Q.cast_count,
    COALESCE(Q.movie_info, 'No Info Available') AS movie_info,
    (SELECT COUNT(DISTINCT c2.person_id) 
     FROM cast_info c2 
     WHERE c2.movie_id IN (SELECT movie_id FROM complete_cast cc WHERE cc.status_id IS NULL)) AS active_cast_count
FROM 
    QualifiedMovies Q
ORDER BY 
    Q.production_year DESC, Q.cast_count DESC;
