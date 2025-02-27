WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.title) AS rn
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary') 
        AND cn.country_code IS NOT NULL
),
HighlightedMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COALESCE(SUM(mk.id)::text, '0') AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.title_id = mk.movie_id
    GROUP BY 
        rm.title_id, rm.title, rm.production_year
)
SELECT 
    hm.title, 
    hm.production_year,
    CASE 
        WHEN hm.keyword_count::integer > 10 THEN 'Highly Tagged'
        WHEN hm.keyword_count::integer BETWEEN 5 AND 10 THEN 'Moderately Tagged'
        ELSE 'Sparsely Tagged'
    END AS tag_level,
    COALESCE((
        SELECT 
            COUNT(DISTINCT c.person_id)
        FROM 
            cast_info c
        WHERE 
            c.movie_id = hm.title_id), 0) AS cast_count
FROM 
    HighlightedMovies hm
WHERE 
    EXISTS (SELECT 1 
            FROM aka_title at 
            WHERE at.title = hm.title AND at.production_year = hm.production_year)
ORDER BY 
    hm.production_year DESC,
    hm.title;
