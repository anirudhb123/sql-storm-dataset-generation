WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(COUNT(DISTINCT ci.person_id), 0) AS cast_count,
        COALESCE(MAX(mi.info), 'N/A') AS movie_info,
        COALESCE(COUNT(DISTINCT mk.keyword), 0) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        aka_title at ON at.title = rm.title AND at.production_year = rm.production_year
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = at.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = cc.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = at.movie_id
    GROUP BY 
        m.id,
        m.title
),
HighRatedMovies AS (
    SELECT 
        md.title,
        md.cast_count,
        md.movie_info,
        md.keyword_count,
        CASE 
            WHEN md.cast_count > 10 THEN 'Highly Casted'
            WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Moderately Casted'
            ELSE 'Low Casted'
        END AS casting_category
    FROM 
        MovieDetails md
    WHERE 
        md.keyword_count > 3
)
SELECT 
    h.title,
    h.cast_count,
    h.movie_info,
    h.casting_category,
    (SELECT STRING_AGG(a.name, ', ') 
     FROM aka_name a 
     JOIN cast_info c ON a.person_id = c.person_id 
     WHERE c.movie_id IN (SELECT movie_id FROM complete_cast WHERE status_id = 1) 
     GROUP BY c.movie_id) AS cast_names
FROM 
    HighRatedMovies h
WHERE 
    h.title IS NOT NULL
ORDER BY 
    h.cast_count DESC;
