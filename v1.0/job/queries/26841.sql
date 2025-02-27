WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        k.keyword AS movie_keyword,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, k.keyword
)

SELECT 
    rm.title_id AS "Title ID",
    rm.movie_title AS "Movie Title",
    rm.production_year AS "Production Year",
    rm.kind_id AS "Kind ID",
    rm.movie_keyword AS "Keyword",
    rm.cast_count AS "Cast Count",
    a.name AS "Actor Name",
    a.md5sum AS "Actor MD5",
    p.info AS "Actor Info"
FROM 
    RankedMovies rm
JOIN 
    complete_cast cc ON rm.title_id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    rm.cast_count > 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
