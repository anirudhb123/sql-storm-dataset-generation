WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        COALESCE(m.production_year, 0) AS production_year,
        a.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(m.production_year, 0) ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')
    LEFT JOIN 
        title m ON a.id = m.id
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND (m.production_year IS NOT NULL OR m.production_year IS NULL)
    GROUP BY 
        a.id, m.production_year
),
HighRankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count,
        rank
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    h.movie_title,
    h.production_year,
    h.cast_count,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = h.movie_title LIMIT 1)) AS keyword_count,
    EXISTS (
        SELECT 
            1 
        FROM 
            movie_companies mc 
        JOIN 
            company_name cn ON mc.company_id = cn.id 
        WHERE 
            mc.movie_id = (SELECT id FROM aka_title WHERE title = h.movie_title LIMIT 1) 
            AND cn.country_code = 'USA'
    ) AS has_us_company,
    STRING_AGG(DISTINCT mi.info, ', ') AS movie_tagline
FROM 
    HighRankedMovies h
LEFT JOIN 
    movie_info mi ON h.movie_id = mi.movie_id
GROUP BY 
    h.movie_title, h.production_year, h.cast_count
ORDER BY 
    h.production_year DESC, h.cast_count DESC;
