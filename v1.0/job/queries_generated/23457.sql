WITH RecursiveTitleHierarchy AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        t.season_nr, 
        t.episode_nr, 
        t.episode_of_id, 
        0 AS hierarchy_level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL
    UNION ALL
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        t.season_nr, 
        t.episode_nr, 
        t.episode_of_id, 
        r.hierarchy_level + 1
    FROM 
        title t
    JOIN 
        RecursiveTitleHierarchy r ON t.episode_of_id = r.title_id
),
FilteredMovies AS (
    SELECT 
        t.title, 
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        MIN(kc.keyword) AS first_keyword,
        MAX(m.production_year) AS max_year
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        keyword kc ON kc.id = mk.keyword_id
    LEFT JOIN 
        movie_info m ON m.movie_id = t.movie_id
    WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
        AND m.info IS NOT NULL
    GROUP BY 
        t.title
    HAVING 
        COUNT(DISTINCT kc.keyword) > 3
),
MovieStats AS (
    SELECT 
        f.title,
        f.keyword_count,
        f.first_keyword,
        f.max_year,
        ROW_NUMBER() OVER (PARTITION BY f.max_year ORDER BY f.keyword_count DESC) AS rank_in_year
    FROM 
        FilteredMovies f
)
SELECT 
    m.title,
    CASE 
        WHEN m.rank_in_year <= 5 THEN 'Top 5' 
        WHEN m.rank_in_year <= 10 THEN 'Top 10'
        ELSE 'Below Top 10'
    END AS rank_category,
    m.keyword_count,
    REPLACE(m.first_keyword, ' ', '_') AS formatted_keyword,
    COALESCE(y.hierarchy_level, -1) AS episode_depth
FROM 
    MovieStats m
LEFT JOIN 
    RecursiveTitleHierarchy y ON m.title LIKE '%' || y.title || '%'
WHERE 
    m.max_year >= 2000
ORDER BY 
    m.keyword_count DESC, m.max_year DESC;
