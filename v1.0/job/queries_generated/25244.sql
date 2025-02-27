WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS title_rank
    FROM 
        aka_title t
    JOIN 
        aka_name a ON t.id = a.id
    WHERE 
        t.production_year >= 2000
),
TopRatedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(r.id) AS role_count
    FROM 
        title m
    JOIN 
        cast_info r ON m.id = r.movie_id
    WHERE 
        m.production_year = 2022
    GROUP BY 
        m.id, m.title, m.production_year
    ORDER BY 
        role_count DESC
    LIMIT 5
),
MovieDetails AS (
    SELECT 
        tr.title AS movie_title,
        tr.production_year,
        ak.aka_name AS alternate_names,
        COUNT(DISTINCT c.id) AS character_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopRatedMovies tr
    JOIN 
        movie_keyword mk ON tr.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON tr.movie_id = cc.movie_id
    JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    GROUP BY 
        tr.title, tr.production_year, ak.aka_name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.alternate_names,
    md.character_count,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.character_count > 5
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC;
