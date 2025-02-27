WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(c.role_id, 0) AS role_id,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS cast_order
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2020
),
FilteredMovies AS (
    SELECT 
        movie_id, title, production_year, role_id,
        COUNT(*) OVER (PARTITION BY production_year) AS total_per_year
    FROM 
        RecursiveMovieCTE
    WHERE 
        role_id IS NOT NULL
),
TopRoles AS (
    SELECT 
        movie_id, title, production_year, role_id,
        RANK() OVER (PARTITION BY production_year, role_id ORDER BY COUNT(*) DESC) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.id
    GROUP BY 
        movie_id, title, production_year, role_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(NULLIF(tr.role_id, 0), 'No Role') AS role_id,
    fm.total_per_year,
    CASE 
        WHEN tr.role_rank = 1 THEN 'Lead Role'
        WHEN tr.role_rank <= 3 THEN 'Supporting Role'
        ELSE 'Minor Role'
    END AS role_category,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM 
    FilteredMovies fm
LEFT JOIN 
    TopRoles tr ON fm.movie_id = tr.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id = fm.movie_id)
WHERE 
    EXISTS (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = fm.movie_id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Award%'))
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, tr.role_id, fm.total_per_year, tr.role_rank
HAVING 
    COUNT(ak.id) > 1
ORDER BY 
    fm.production_year DESC, role_category DESC NULLS LAST;
