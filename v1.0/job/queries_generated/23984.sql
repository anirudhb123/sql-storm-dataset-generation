WITH RecursiveHierarchy AS (
    SELECT 
        c.movie_id, 
        c.person_id, 
        ca.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rank
    FROM 
        cast_info c
    JOIN 
        aka_name ca ON c.person_id = ca.person_id
    WHERE 
        ca.name IS NOT NULL
),
MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT ca.actor_name ORDER BY rank SEPARATOR ', ') AS actors,
        CASE 
            WHEN COUNT(DISTINCT cm.company_id) > 1 THEN 'Multiple Companies' 
            ELSE 'Single Company' 
        END AS company_status
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies cm ON mt.id = cm.movie_id
    LEFT JOIN 
        RecursiveHierarchy rh ON mt.id = rh.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.actors,
        kc.keyword_count,
        COALESCE(md.company_status, 'No Company') AS company_status
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordCounts kc ON md.movie_id = kc.movie_id
)
SELECT 
    FR.title,
    FR.production_year,
    FR.actors,
    FR.keyword_count,
    FR.company_status,
    CASE 
        WHEN FR.keyword_count IS NULL THEN 'No Keywords'
        WHEN FR.keyword_count > 5 THEN 'Rich in Keywords'
        WHEN FR.keyword_count BETWEEN 1 AND 5 THEN 'Moderate Keywords'
        ELSE 'Unclassified'
    END AS keyword_classification
FROM 
    FinalResults FR
WHERE 
    (FR.production_year > 2000 OR FR.company_status = 'Multiple Companies')
ORDER BY 
    FR.production_year DESC, FR.title
FETCH FIRST 50 ROWS ONLY;

This SQL query combines various elements like Common Table Expressions (CTEs), GROUP BY, window functions, CASE statements, and LEFT joins to create a complex performance benchmarking scenario. It filters and classifies movies based on the number of keywords and the number of associated companies while also demonstrating advanced SQL constructs and accommodating for NULL values.
