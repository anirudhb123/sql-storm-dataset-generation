
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(ci.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors_list,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
TopCastMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.cast_count,
        r.actors_list
    FROM 
        RankedMovies r
    WHERE 
        r.rank_within_year <= 3
),
KeywordedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
)
SELECT 
    t.title AS Movie_Title,
    t.production_year AS Production_Year,
    t.cast_count AS Number_Of_Cast,
    t.actors_list AS Leading_Actors,
    k.keywords AS Keywords
FROM 
    TopCastMovies t
LEFT JOIN 
    KeywordedMovies k ON t.movie_id = k.title_id
ORDER BY 
    t.production_year DESC, t.cast_count DESC;
