WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_cast_members,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.id) AS year_rank
    FROM 
        aka_title t 
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        title,
        production_year,
        total_cast_members,
        total_companies,
        year_rank
    FROM 
        RecursiveMovieCTE
    WHERE 
        (total_cast_members > 5 OR production_year = 2020 OR title LIKE '%[Ss]equel%')
        AND year_rank <= 10
),
CriticalMovies AS (
    SELECT 
        f.*, 
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = f.movie_id) AS keywords_count,
        (SELECT ARRAY_AGG(DISTINCT kind) FROM kind_type kt JOIN aka_title a ON kt.id = a.kind_id WHERE a.movie_id = f.movie_id) AS kind_types
    FROM 
        FilteredMovies f
),
FinalSelection AS (
    SELECT 
        cm.movie_id, 
        cm.title, 
        cm.production_year,
        cm.total_cast_members,
        cm.total_companies,
        cm.keywords_count,
        cm.kind_types,
        CASE 
            WHEN cm.production_year < 2000 THEN 'Classic' 
            WHEN cm.production_year BETWEEN 2000 AND 2010 THEN 'Modern' 
            ELSE 'Recent' 
        END AS era,
        CASE 
            WHEN cm.keywords_count IS NULL THEN 'No Keywords'
            WHEN cm.keywords_count > 3 THEN 'Rich in Keywords' 
            ELSE 'Few Keywords' 
        END AS keyword_status
    FROM 
        CriticalMovies cm
)
SELECT 
    fs.movie_id,
    fs.title,
    fs.production_year,
    fs.total_cast_members,
    fs.total_companies,
    fs.keywords_count,
    fs.kind_types,
    fs.era,
    fs.keyword_status
FROM 
    FinalSelection fs
WHERE 
    fs.total_companies > 0
    OR fs.production_year IS NULL
ORDER BY 
    fs.production_year DESC, fs.total_cast_members DESC
LIMIT 100;
