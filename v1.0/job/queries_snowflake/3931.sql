
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieKeywords AS (
    SELECT 
        m.title_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        TopMovies m ON mk.movie_id = m.title_id
    GROUP BY 
        m.title_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(a.name, 'Unknown Actor') AS lead_actor,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = tm.title_id) AS company_count
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON ci.movie_id = tm.title_id AND ci.nr_order = 1
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.title_id
ORDER BY 
    tm.production_year DESC, tm.title;
