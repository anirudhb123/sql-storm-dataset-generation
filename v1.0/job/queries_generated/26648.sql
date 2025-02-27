WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        aka_names, 
        keywords, 
        cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast <= 10
)
SELECT 
    t.movie_id,
    t.title,
    t.production_year,
    string_agg(DISTINCT unnest(t.aka_names), ', ') AS combined_aka_names,
    string_agg(DISTINCT unnest(t.keywords), ', ') AS combined_keywords,
    t.cast_count
FROM 
    TopRankedMovies t
GROUP BY 
    t.movie_id, t.title, t.production_year, t.cast_count
ORDER BY 
    t.cast_count DESC, t.production_year DESC;
