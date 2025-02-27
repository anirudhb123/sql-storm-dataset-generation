WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) OVER (PARTITION BY t.id) AS total_cast,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) OVER (PARTITION BY t.id) AS avg_order
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.production_year > 2000
), 
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.avg_order,
        cm.companies,
        mk.keywords 
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovies cm ON rm.movie_id = cm.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.total_cast > 3 
        AND rm.avg_order < 2.5
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.companies, 'No Company Info') AS companies,
    COALESCE(fm.keywords, 'No Keywords') AS keywords
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.total_cast DESC
LIMIT 10;

-- Hierarchical Data as a Corner Case
WITH RECURSIVE MovieLinks AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = 1 -- Assume '1' is a specific link type of interest

    UNION ALL 

    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        ml.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieLinks ml2 ON ml.movie_id = ml2.linked_movie_id
    WHERE 
        ml.depth < 5
)
SELECT 
    mk.title,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_count
FROM 
    MovieLinks ml
JOIN 
    aka_title mk ON ml.linked_movie_id = mk.id
GROUP BY 
    mk.title
HAVING 
    COUNT(DISTINCT ml.linked_movie_id) > 5
ORDER BY 
    linked_count DESC
LIMIT 5;
