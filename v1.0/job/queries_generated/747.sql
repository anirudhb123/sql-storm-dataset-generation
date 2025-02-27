WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count,
        COALESCE(SUM(CASE WHEN ci.kind_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS comp_cast_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
    WHERE 
        t.production_year >= 2000
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count, 
        comp_cast_count,
        rank
    FROM 
        RankedMovies
    WHERE 
        actor_count >= 5 
        AND comp_cast_count > 0
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    f.comp_cast_count,
    CASE 
        WHEN f.actor_count > 20 THEN 'Large Cast' 
        WHEN f.actor_count BETWEEN 10 AND 20 THEN 'Medium Cast' 
        ELSE 'Small Cast' 
    END AS cast_size,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id IN (SELECT id FROM aka_title WHERE title = f.title)) THEN 'Has Keywords' 
        ELSE 'No Keywords' 
    END AS keyword_status
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.title ASC
LIMIT 50;
