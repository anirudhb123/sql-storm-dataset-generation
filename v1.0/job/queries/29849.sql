
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        COUNT(DISTINCT ki.id) AS keyword_count,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_with_role
    FROM 
        title AS m
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword AS ki ON ki.id = mk.keyword_id
    LEFT JOIN 
        cast_info AS ci ON ci.movie_id = m.id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        keyword_count, 
        avg_cast_with_role
    FROM 
        RankedMovies
    WHERE 
        production_year > 2000 AND
        keyword_count > 5
),
MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        FilteredMovies AS fm
    LEFT JOIN 
        complete_cast AS cc ON cc.movie_id = fm.movie_id
    LEFT JOIN 
        aka_name AS a ON a.person_id = cc.subject_id
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = fm.movie_id
    LEFT JOIN 
        company_type AS c ON c.id = mc.company_type_id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year
)
SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    md.actor_names,
    md.company_types
FROM 
    MovieDetails AS md
ORDER BY 
    md.production_year DESC, 
    md.title;
