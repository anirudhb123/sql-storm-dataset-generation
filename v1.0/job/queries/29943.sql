WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS known_aliases
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title, a.production_year, a.id
),
top_movies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.known_aliases,
    ki.kind AS movie_kind,
    mp.name AS production_company
FROM 
    top_movies tm
LEFT JOIN 
    title t ON tm.movie_id = t.id
LEFT JOIN 
    kind_type ki ON t.kind_id = ki.id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name mp ON mc.company_id = mp.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.total_cast DESC;
