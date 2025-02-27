WITH RecursiveMovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ml.linked_movie_id, -1) AS linked_movie_id,
        1 AS depth
    FROM 
        aka_title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        COALESCE(ml.linked_movie_id, -1) AS linked_movie_id,
        depth + 1
    FROM 
        RecursiveMovieHierarchy rm
    JOIN 
        movie_link ml ON rm.linked_movie_id = ml.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        SUM(CASE WHEN cm.kind_id IS NOT NULL THEN 1 ELSE 0 END) AS total_companies,
        ROW_NUMBER() OVER(PARTITION BY rm.production_year ORDER BY rm.production_year DESC, total_companies DESC) AS rank
    FROM 
        RecursiveMovieHierarchy rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type cm ON mc.company_type_id = cm.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
MovieDetails AS (
    SELECT 
        fm.*,
        CASE 
            WHEN fm.production_year IS NULL THEN 'Unknown Year'
            ELSE CAST(fm.production_year AS TEXT)
        END AS production_year_info,
        MAX(CASE WHEN c.gender = 'F' THEN c.name END) OVER (PARTITION BY fm.movie_id) AS female_cast_member
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        cast_info ci ON fm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year_info,
    md.total_companies,
    md.female_cast_member,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    md.total_companies > 0
GROUP BY 
    md.movie_id, md.title, md.production_year_info, md.total_companies, md.female_cast_member
HAVING 
    COUNT(DISTINCT k.keyword) > 0 OR md.female_cast_member IS NOT NULL
ORDER BY 
    md.production_year_info DESC, 
    md.total_companies DESC
LIMIT 100;
