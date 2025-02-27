WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        tk.keyword,
        COUNT(tc.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(tc.id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword tk ON mk.keyword_id = tk.id
    JOIN 
        cast_info tc ON t.id = tc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, tk.keyword
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.keyword,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
PersonInfo AS (
    SELECT 
        p.name,
        pi.info,
        pi.note
    FROM 
        aka_name p
    JOIN 
        person_info pi ON p.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.total_cast,
    pi.name,
    pi.info AS biography
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
LEFT JOIN 
    PersonInfo pi ON ci.person_id = pi.id
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;

