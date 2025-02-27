WITH RankedMovies AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(cc.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.person_id) DESC) AS rnk
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast comp ON mt.id = comp.movie_id
    LEFT JOIN 
        cast_info cc ON comp.subject_id = cc.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
),
MovieKeywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),
DirectorInfo AS (
    SELECT 
        ci.movie_id,
        cn.name AS director_name,
        ci.note AS director_note
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    WHERE 
        ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Director')
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.cast_count, 
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(di.director_name, 'Unknown Director') AS director_name,
    COALESCE(di.director_note, 'No notes') AS director_note
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.title = mk.movie_id 
LEFT JOIN 
    DirectorInfo di ON rm.title = di.movie_id
WHERE 
    rm.rnk <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
