WITH MovieData AS (
    SELECT 
        t.title AS movie_title,
        a.name AS person_name,
        c.nr_order,
        k.keyword AS movie_keyword,
        cc.kind AS cast_type,
        c.note AS cast_note
    FROM 
        aka_title AS t
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS c ON cc.subject_id = c.id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
CountedData AS (
    SELECT 
        md.movie_title,
        md.person_name,
        md.nr_order,
        md.movie_keyword,
        md.cast_type,
        md.cast_note,
        COUNT(md.movie_keyword) OVER (PARTITION BY md.movie_title) AS keyword_count
    FROM 
        MovieData md
)
SELECT 
    movie_title,
    person_name,
    nr_order,
    movie_keyword,
    cast_type,
    cast_note,
    keyword_count
FROM 
    CountedData
WHERE 
    keyword_count > 1
ORDER BY 
    movie_title ASC, 
    nr_order DESC;
