WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL
),
CharCount AS (
    SELECT
        title,
        LENGTH(title) - LENGTH(REPLACE(title, 'a', '')) AS 'a_count',
        LENGTH(title) - LENGTH(REPLACE(title, 'e', '')) AS 'e_count'
    FROM 
        RankedMovies
    WHERE 
        title_rank <= 5
),
FilteredMovies AS (
    SELECT 
        m.*,
        cc.a_count,
        cc.e_count
    FROM 
        RankedMovies m
    JOIN 
        CharCount cc ON m.title = cc.title
    WHERE 
        EXISTS (
            SELECT 1
            FROM movie_keyword mk
            WHERE mk.movie_id = m.movie_id
            AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword IN ('Action', 'Drama'))
        )
        AND (cc.a_count > 0 OR cc.e_count > 0)
),
FinalResults AS (
    SELECT 
        f.title,
        f.production_year,
        COALESCE(ARRAY_AGG(DISTINCT CONCAT(c.name, ' (', rt.role, ')')) FILTER (WHERE c.name IS NOT NULL), '{}'::text[]) AS cast_details,
        f.cast_count
    FROM 
        FilteredMovies f
    LEFT JOIN 
        complete_cast cc ON f.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.person_id = c.person_id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        f.title, f.production_year, f.cast_count
)
SELECT 
    title,
    production_year,
    cast_details,
    cast_count
FROM 
    FinalResults
WHERE 
    cast_count IS NOT NULL
ORDER BY 
    production_year DESC, title ASC
LIMIT 50 OFFSET 10;
