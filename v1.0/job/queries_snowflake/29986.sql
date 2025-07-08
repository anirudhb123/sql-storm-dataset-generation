
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),

PopularYears AS (
    SELECT 
        production_year,
        AVG(total_cast) AS avg_cast_per_movie
    FROM 
        RankedMovies
    GROUP BY 
        production_year
)

SELECT 
    rm.production_year,
    COUNT(rm.movie_id) AS number_of_movies,
    rm.total_cast,
    rm.actors,
    p.avg_cast_per_movie,
    (SELECT COUNT(*) FROM aka_title WHERE production_year = rm.production_year) AS total_movies_in_year
FROM 
    RankedMovies rm
JOIN 
    PopularYears p ON rm.production_year = p.production_year
WHERE 
    rm.rank_by_cast <= 5
GROUP BY 
    rm.production_year, rm.total_cast, rm.actors, p.avg_cast_per_movie
ORDER BY 
    rm.production_year, number_of_movies DESC;
