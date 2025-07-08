
WITH Recursive_AkaNames AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        a.name AS aka_name,
        a.imdb_index,
        a.md5sum,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.name) AS rank
    FROM 
        aka_name a
),
Filtered_Titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
Aggregated_Cast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count,
        LISTAGG(DISTINCT r.role, ', ') WITHIN GROUP (ORDER BY r.role) AS roles_in_movie
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    a.person_id,
    a.aka_name,
    f.title,
    f.production_year,
    ac.cast_count,
    ac.roles_in_movie
FROM 
    Recursive_AkaNames a
JOIN 
    complete_cast cc ON a.person_id = cc.subject_id
JOIN 
    Filtered_Titles f ON cc.movie_id = f.title_id
JOIN 
    Aggregated_Cast ac ON f.title_id = ac.movie_id
WHERE 
    a.rank = 1
ORDER BY 
    f.production_year DESC, a.aka_name;
