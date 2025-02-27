WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COALESCE(cc.comp_cast_count, 0) AS comp_cast_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kc ON mk.keyword_id = kc.id
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(DISTINCT person_id) AS comp_cast_count 
        FROM 
            cast_info 
        GROUP BY 
            movie_id
    ) AS cc ON t.id = cc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, cc.comp_cast_count
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        keyword_count,
        comp_cast_count,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC, comp_cast_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.comp_cast_count,
    array_agg(DISTINCT ak.name) AS aka_names,
    STRING_AGG(DISTINCT ci.note, ', ') AS role_notes
FROM 
    top_movies AS tm
LEFT JOIN 
    complete_cast AS cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name AS ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    cast_info AS ci ON cc.movie_id = ci.movie_id AND cc.subject_id = ci.person_id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.keyword_count, tm.comp_cast_count
ORDER BY 
    tm.rank;
