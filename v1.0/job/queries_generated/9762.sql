WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(k.keyword) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT p.name ORDER BY p.name) AS cast_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, c.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_name,
    md.cast_names,
    k.keyword AS popular_keyword
FROM 
    MovieDetails md
JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    k.keyword IN (SELECT DISTINCT keyword FROM keyword ORDER BY RANDOM() LIMIT 5)
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
