
WITH 
TopMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(c.person_id) AS cast_count,
        SUM(CASE WHEN c.role_id IS NULL THEN 0 ELSE 1 END) AS actual_roles,
        AVG(CASE WHEN mii.info IS NOT NULL THEN LENGTH(mii.info) ELSE 0 END) AS avg_info_length,
        t.production_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        movie_info mii ON t.movie_id = mii.movie_id 
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        TM.movie_id,
        TM.title,
        TM.cast_count,
        TM.actual_roles,
        TM.avg_info_length,
        ROW_NUMBER() OVER (ORDER BY TM.cast_count DESC) AS rnk
    FROM 
        TopMovies TM
    WHERE 
        TM.cast_count > 5 
        AND TM.avg_info_length > 20
),
MovieGenres AS (
    SELECT 
        FM.movie_id,
        LISTAGG(DISTINCT kt.keyword, ', ') WITHIN GROUP (ORDER BY kt.keyword) AS genres
    FROM 
        FilteredMovies FM
    JOIN 
        movie_keyword mk ON FM.movie_id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        FM.movie_id
),
FinalResults AS (
    SELECT 
        FM.title,
        FM.cast_count,
        FM.actual_roles,
        MG.genres
    FROM 
        FilteredMovies FM
    LEFT JOIN 
        MovieGenres MG ON FM.movie_id = MG.movie_id
    WHERE 
        FM.rnk < 10
)
SELECT 
    FR.title,
    COALESCE(FR.cast_count, 0) AS total_cast,
    CASE 
        WHEN FR.actual_roles = 0 THEN 'No roles assigned'
        ELSE CONCAT(FR.actual_roles, ' roles assigned')
    END AS role_assignment,
    COALESCE(FR.genres, 'No genres available') AS associated_genres
FROM 
    FinalResults FR
ORDER BY 
    FR.title;
