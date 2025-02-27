WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_pct
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_cast DESC) AS rank_order
    FROM 
        MovieDetails
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.has_note_pct,
    ak.name AS actor_name,
    cl.name AS character_name,
    ct.kind AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id AND ak.md5sum IS NOT NULL
LEFT JOIN 
    char_name cl ON ci.id = cl.id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.rank_order <= 10
    AND (ak.name ILIKE '%Smith%' OR cl.name LIKE 'Hero%')
ORDER BY 
    tm.total_cast DESC, tm.production_year ASC;
