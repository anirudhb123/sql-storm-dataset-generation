
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_role,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        total_cast,
        avg_cast_role
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.total_cast,
        tm.avg_cast_role,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
        COALESCE(SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS info_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.total_cast, tm.avg_cast_role
)
SELECT 
    md.movie_id,
    md.title,
    md.total_cast,
    md.avg_cast_role,
    md.actor_names,
    md.note_count,
    md.info_count,
    (CASE 
         WHEN md.avg_cast_role IS NULL THEN 'No Roles' 
         ELSE 'Has Roles' 
     END) AS role_status
FROM 
    MovieDetails md
ORDER BY 
    md.total_cast DESC, md.title;
