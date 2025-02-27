WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
StudyMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.cast_count,
        COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
        CASE 
            WHEN rm.cast_count > 5 THEN 'Large Cast'
            WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
            ELSE 'Small Cast' 
        END AS cast_size_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.title = (SELECT title FROM aka_title WHERE id IN (SELECT movie_id FROM movie_info WHERE info_type_id = 1))
    WHERE 
        rm.rank <= 10
),
FinalOutput AS (
    SELECT 
        sm.title, 
        sm.production_year, 
        sm.cast_count, 
        sm.movie_keyword, 
        sm.cast_size_category,
        string_agg(distinct r.role, ', ') AS roles_played
    FROM 
        StudyMovies sm
    LEFT JOIN 
        cast_info ci ON sm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        sm.title, sm.production_year, sm.cast_count, sm.movie_keyword, sm.cast_size_category
)
SELECT 
    fo.title, 
    fo.production_year, 
    fo.cast_count, 
    fo.movie_keyword, 
    fo.cast_size_category,
    COALESCE(fo.roles_played, 'No Roles Assigned') AS roles_assigned
FROM 
    FinalOutput fo
ORDER BY 
    fo.production_year DESC, fo.cast_count DESC;
