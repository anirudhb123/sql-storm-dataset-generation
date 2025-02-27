WITH Recursive_AKA AS (
    SELECT 
        ak.id AS aka_id,
        ak.name AS aka_name,
        ak.person_id,
        ak.imdb_index AS aka_imdb_index,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ak.name) AS rn
    FROM 
        aka_name ak
), 
Movies_Cast AS (
    SELECT 
        c.id AS cast_id,
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        p.name AS person_name,
        p.imdb_index AS person_imdb_index,
        c.note AS cast_note
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        aka_title m ON c.movie_id = m.movie_id
    WHERE 
        m.production_year >= 2000
), 
Keyword_Info AS (
    SELECT 
        k.id AS keyword_id,
        k.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.id, k.keyword
    HAVING 
        COUNT(mk.movie_id) > 5
) 
SELECT 
    ma.aka_name,
    mv.movie_title,
    mv.production_year,
    mv.cast_note,
    ki.keyword,
    ki.movie_count
FROM 
    Movies_Cast mv
JOIN 
    Recursive_AKA ma ON mv.person_imdb_index = ma.aka_imdb_index
JOIN 
    Keyword_Info ki ON mv.movie_id IN (
        SELECT movie_id 
        FROM movie_keyword 
        WHERE keyword_id = ki.keyword_id
    )
WHERE 
    ma.rn <= 3
ORDER BY 
    mv.production_year DESC, 
    ma.aka_name, 
    ki.movie_count DESC;
