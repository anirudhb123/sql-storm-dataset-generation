WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
BestMovies AS (
    SELECT 
        title_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast = 1
),
MovieDetails AS (
    SELECT 
        bm.title,
        bm.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        BestMovies bm
    LEFT JOIN 
        aka_title at ON bm.title_id = at.movie_id
    LEFT JOIN 
        aka_name ak ON at.id = ak.id
    LEFT JOIN 
        movie_keyword mk ON bm.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        bm.title, bm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
    AND (md.aka_names IS NOT NULL OR md.keywords IS NOT NULL)
ORDER BY 
    md.production_year DESC, 
    md.title;
