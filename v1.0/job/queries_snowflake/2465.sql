
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank,
        COUNT(DISTINCT c.person_id) AS cast_count
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
        rank <= 3 
),
MovieKeywords AS (
    SELECT 
        m.title_id, 
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk 
    JOIN 
        TopMovies m ON mk.movie_id = m.title_id
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        m.title_id
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ak.name, 'Unknown') AS actor_name,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic' 
        ELSE 'Modern' 
    END AS classification
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.title_id
WHERE 
    ak.name IS NOT NULL 
    OR (tm.production_year IS NOT NULL AND tm.production_year > 2015)
ORDER BY 
    tm.production_year DESC, 
    tm.title;
