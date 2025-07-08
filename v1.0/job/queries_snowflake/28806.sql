
WITH movie_title_info AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.title, t.production_year, k.keyword
), ranked_movies AS (
    SELECT 
        m.*, 
        RANK() OVER (PARTITION BY m.movie_title ORDER BY m.num_cast_members DESC) AS rank_with_cast
    FROM 
        movie_title_info m
)
SELECT 
    r.movie_title,
    r.production_year,
    r.keyword,
    r.num_cast_members,
    r.aka_names
FROM 
    ranked_movies r
WHERE 
    r.rank_with_cast = 1 
ORDER BY 
    r.production_year DESC, 
    r.movie_title;
