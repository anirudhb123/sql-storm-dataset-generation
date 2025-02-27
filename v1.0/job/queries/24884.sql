WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        COALESCE(mci.company_id, 0) AS company_id,
        COALESCE(cast_info.role_id, 0) AS role_id,
        DENSE_RANK() OVER (PARTITION BY mt.id ORDER BY COALESCE(cast_info.nr_order, 999) ASC) AS role_ordering,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS title_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mci ON mt.id = mci.movie_id
    LEFT JOIN 
        cast_info ON mt.id = cast_info.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        r.movie_id, 
        r.title, 
        r.production_year, 
        r.company_id,
        r.role_id
    FROM 
        RecursiveMovieCTE r
    WHERE 
        r.role_ordering <= 5 
        AND r.company_id IS NOT NULL
),
MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        cm.name AS company_name,
        COUNT(DISTINCT cp.id) AS cast_count,
        SUM(CASE WHEN cp.note LIKE '%Starring%' THEN 1 ELSE 0 END) AS starring_roles
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        company_name cm ON fm.company_id = cm.id
    LEFT JOIN 
        cast_info cp ON fm.movie_id = cp.movie_id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year, cm.name
)
SELECT 
    md.movie_id, 
    md.title, 
    md.production_year,
    md.company_name,
    md.cast_count,
    md.starring_roles,
    CASE 
        WHEN md.cast_count > 10 THEN 'Large Cast'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN md.starring_roles > 0 THEN 'Has Starring Roles'
        ELSE 'No Starring Roles'
    END AS starring_info,
    ARRAY_AGG(DISTINCT kw.keyword) FILTER (WHERE kw.keyword IS NOT NULL) AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.company_name, md.cast_count, md.starring_roles
HAVING 
    md.production_year >= 2000 
    AND (md.starring_roles IS NULL OR md.starring_roles > 1)
ORDER BY 
    md.production_year DESC, md.cast_count DESC;