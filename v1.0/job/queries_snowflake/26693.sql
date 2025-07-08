
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        cn.country_code = 'USA' 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
TopDirectors AS (
    SELECT 
        director_name, 
        COUNT(movie_id) AS total_movies 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast <= 5  
    GROUP BY 
        director_name 
    ORDER BY 
        total_movies DESC
    LIMIT 10
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    tm.total_movies AS director_movies,
    mk.keywords 
FROM 
    RankedMovies rm
JOIN 
    TopDirectors tm ON rm.director_name = tm.director_name
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_by_cast <= 10  
ORDER BY 
    rm.production_year DESC, tm.total_movies DESC;
