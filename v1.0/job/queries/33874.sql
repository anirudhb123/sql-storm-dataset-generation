WITH RECURSIVE MoviePaths AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        1 AS path_depth,
        title.episode_of_id
    FROM 
        title
    WHERE 
        title.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        t.id,
        t.title,
        t.production_year,
        mp.path_depth + 1,
        t.episode_of_id
    FROM 
        title t
    JOIN 
        MoviePaths mp ON t.episode_of_id = mp.movie_id
),
AggregateAttendance AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind = 'Production'
    GROUP BY 
        mc.movie_id
),
TitleInfo AS (
    SELECT 
        ti.movie_id,
        ti.info AS tagline
    FROM 
        movie_info ti
    JOIN 
        info_type it ON ti.info_type_id = it.id 
    WHERE 
        it.info = 'tagline'
)
SELECT 
    mp.title AS movie_title,
    mp.production_year,
    COALESCE(a.cast_count, 0) AS num_cast_members,
    COALESCE(c.company_count, 0) AS num_production_companies,
    ti.tagline,
    ROW_NUMBER() OVER (PARTITION BY mp.production_year ORDER BY mp.production_year) AS rank_within_year
FROM 
    MoviePaths mp
LEFT JOIN 
    AggregateAttendance a ON mp.movie_id = a.movie_id
LEFT JOIN 
    CompanyCounts c ON mp.movie_id = c.movie_id
LEFT JOIN 
    TitleInfo ti ON mp.movie_id = ti.movie_id
WHERE 
    mp.path_depth < 3
    AND (mp.production_year >= 2000 AND mp.production_year <= 2023)
ORDER BY 
    mp.production_year DESC, 
    rank_within_year;
