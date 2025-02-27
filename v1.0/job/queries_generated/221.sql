WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword) AS total_keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
TopMovies AS (
    SELECT 
        md.* 
    FROM 
        MovieDetails md
    WHERE 
        md.total_cast > 5 AND md.total_keywords > 10
)
SELECT 
    mv.movie_id, 
    mv.title, 
    mv.production_year,
    cb.kind AS company_type,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = mv.movie_id 
     AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')) AS has_summary,
    COALESCE(NULLIF(ca.person_role_id, 0), 'No Role Assigned') AS person_role
FROM 
    TopMovies mv
LEFT JOIN 
    movie_companies mc ON mv.movie_id = mc.movie_id
LEFT JOIN 
    company_type cb ON mc.company_type_id = cb.id
LEFT JOIN 
    cast_info ca ON mv.movie_id = ca.movie_id
WHERE 
    cb.kind IS NOT NULL
ORDER BY 
    mv.production_year DESC, mv.title;
