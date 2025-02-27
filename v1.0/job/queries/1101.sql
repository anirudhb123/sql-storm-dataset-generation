
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(cc.movie_id) AS cast_count,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    GROUP BY 
        m.id, m.title
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.cast_count,
        md.cast_names,
        COALESCE(k.keyword, 'No Keyword') AS movie_keyword
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_keyword mk ON md.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    t.production_year,
    t.title,
    COALESCE(m.cast_count, 0) AS total_cast,
    m.cast_names,
    t.title_rank,
    COUNT(DISTINCT mk2.movie_id) AS related_movies_count
FROM 
    RankedTitles t
LEFT JOIN 
    TopMovies m ON t.title_id = m.movie_id
LEFT JOIN 
    movie_link ml ON m.movie_id = ml.movie_id
LEFT JOIN 
    title t2 ON ml.linked_movie_id = t2.id
LEFT JOIN 
    movie_keyword mk2 ON t2.id = mk2.movie_id
WHERE 
    t.title_rank <= 5
GROUP BY 
    t.production_year, t.title, m.cast_count, m.cast_names, t.title_rank
ORDER BY 
    t.production_year DESC, t.title;
