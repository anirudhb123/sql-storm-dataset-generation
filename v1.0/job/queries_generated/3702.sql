WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
HighCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        HighCastMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title, m.production_year
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.keywords, 'No Keywords') AS keywords,
    n.name AS main_actor,
    CASE 
        WHEN n.gender = 'M' THEN 'Male'
        WHEN n.gender = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS actor_gender
FROM 
    MoviesWithKeywords m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name n ON c.person_id = n.person_id
WHERE 
    cc.nr_order = 1
ORDER BY 
    m.production_year DESC, m.title;
