
WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ak.name AS author_name,
        COUNT(*) OVER (PARTITION BY at.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
),
FilteredMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        author_name,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        cast_count > 3
)

SELECT 
    fm.title,
    fm.production_year,
    LISTAGG(fm.author_name, ', ') WITHIN GROUP (ORDER BY fm.author_name) AS cast_members,
    COUNT(DISTINCT ci.role_id) AS unique_roles,
    MAX(CASE WHEN ci.note IS NOT NULL THEN 'Yes' ELSE 'No' END) AS has_notes
FROM 
    FilteredMovies fm
JOIN 
    cast_info ci ON fm.title_id = ci.movie_id
GROUP BY 
    fm.title_id, fm.title, fm.production_year
ORDER BY 
    fm.production_year DESC, 
    unique_roles DESC;
