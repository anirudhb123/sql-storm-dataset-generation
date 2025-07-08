
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title AS t
        JOIN cast_info AS c ON t.id = c.movie_id
        LEFT JOIN aka_name AS ak ON c.person_id = ak.person_id
        LEFT JOIN movie_keyword AS mk ON t.id = mk.movie_id
        LEFT JOIN keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names,
        rm.keywords
    FROM 
        ranked_movies AS rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    LISTAGG(DISTINCT ci.note, '; ') WITHIN GROUP (ORDER BY ci.note) AS cast_notes
FROM 
    top_movies AS tm
    LEFT JOIN complete_cast AS cc ON tm.movie_id = cc.movie_id
    LEFT JOIN cast_info AS ci ON cc.subject_id = ci.person_id
GROUP BY 
    tm.title, tm.production_year, tm.cast_count, tm.aka_names
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
