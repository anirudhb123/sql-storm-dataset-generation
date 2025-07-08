
WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM aka_title AS t
    LEFT JOIN cast_info AS c ON t.id = c.movie_id
    LEFT JOIN aka_name AS a ON c.person_id = a.person_id
    LEFT JOIN movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN keyword AS kc ON mk.keyword_id = kc.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
),
MovieStats AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actors,
        cast_count,
        year_rank,
        keyword_count,
        CASE 
            WHEN cast_count > 15 AND keyword_count < 3 THEN 'Overcrowded Casting'
            WHEN cast_count < 5 THEN 'Low Interest'
            ELSE 'Moderate'
        END AS casting_quality
    FROM RecursiveMovieCTE
),
RankedMovies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY casting_quality ORDER BY production_year DESC) AS quality_rank
    FROM MovieStats
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.actors,
    m.cast_count,
    m.casting_quality,
    COALESCE(mi.info, 'No additional info') AS movie_info,
    CASE 
        WHEN m.year_rank = 1 THEN 'First in Year'
        ELSE 'Not First'
    END AS year_status,
    EXISTS (
        SELECT 1 
        FROM movie_companies mc 
        WHERE mc.movie_id = m.movie_id AND mc.company_type_id IS NULL
    ) AS has_null_company_type
FROM RankedMovies m
LEFT JOIN movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN info_type it ON mi.info_type_id = it.id
WHERE m.quality_rank <= 5
ORDER BY m.casting_quality DESC, m.production_year ASC;
