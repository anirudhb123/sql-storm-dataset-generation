
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(ARRAY_AGG(DISTINCT p.name)::STRING, 'No Cast') AS cast_names,
        COUNT(DISTINCT kc.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN 
        movie_keyword kc ON t.id = kc.movie_id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keyword_count,
        RANK() OVER (ORDER BY md.keyword_count DESC) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    t.title AS "Title",
    t.production_year AS "Year",
    t.cast_names AS "Cast",
    t.keyword_count AS "Keyword Count"
FROM 
    TopMovies t
WHERE 
    t.rank <= 10
ORDER BY 
    t.production_year DESC,
    t.keyword_count DESC;
