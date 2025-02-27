WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
CompanyWithMostMovies AS (
    SELECT 
        mc.company_id,
        c.name,
        COUNT(mc.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(mc.movie_id) DESC) AS rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.company_id, c.name
), 
MoviesWithNulls AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        c.name AS company_name,
        COALESCE(ci.nr_order, -1) AS nr_order_value
    FROM 
        RankedMovies r
    LEFT JOIN 
        movie_companies mc ON r.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON r.movie_id = ci.movie_id
    WHERE 
        r.rank <= 10 -- Top 10 ranked movies
    AND 
        (c.name IS NULL OR ci.nr_order IS NULL OR ci.nr_order > 3) -- Fascinating filter on NULLs
), 
DistinctKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
) 
SELECT 
    m.title,
    m.production_year,
    m.company_name,
    m.nr_order_value,
    COALESCE(k.keywords, 'No Keywords') AS keywords
FROM 
    MoviesWithNulls m
LEFT JOIN 
    DistinctKeywords k ON m.movie_id = k.movie_id
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = m.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
    )
OR 
    m.nr_order_value = -1 -- Include movies with no cast info
ORDER BY 
    m.production_year DESC, m.title;
