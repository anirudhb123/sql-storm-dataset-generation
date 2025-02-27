WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title AS t
    WHERE 
        t.kind_id IN (1, 2)  
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        SUM(CASE WHEN r.role = 'Director' THEN 1 ELSE 0 END) AS director_count
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
SelectedMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        cd.total_cast,
        cd.cast_names,
        mk.keywords,
        CASE 
            WHEN cd.director_count = 0 THEN 'No Directors Listed'
            ELSE 'Directors Available'
        END AS director_status
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        CastDetails AS cd ON rm.title_id = cd.movie_id
    LEFT JOIN 
        MovieKeywords AS mk ON rm.title_id = mk.movie_id
    WHERE 
        rm.rn <= 5  
)
SELECT 
    s.title,
    s.production_year,
    s.total_cast,
    COALESCE(s.cast_names, 'Unknown') AS cast_names,
    COALESCE(s.keywords, 'None') AS keywords,
    s.director_status,
    CASE 
        WHEN s.total_cast IS NULL THEN 'No Cast'
        WHEN s.total_cast > 10 THEN 'Large Cast'
        ELSE 'Small to Medium Cast'
    END AS cast_size_category
FROM 
    SelectedMovies AS s
WHERE 
    s.production_year BETWEEN 2000 AND 2020
ORDER BY 
    s.production_year DESC, s.title;