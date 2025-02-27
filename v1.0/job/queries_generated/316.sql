WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY a.production_year) AS total_movies
    FROM 
        aka_title a 
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    WHERE 
        a.production_year IS NOT NULL 
        AND a.production_year > 2000
),
TitleStatistics AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count,
        AVG(total_movies) AS avg_movies_per_year
    FROM 
        RankedMovies
    GROUP BY 
        production_year
),
PersonFeatures AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS movies_with_notes
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
)
SELECT 
    p.name AS actor_name,
    ps.production_year,
    ps.movie_count,
    pf.total_movies,
    pf.movies_with_notes,
    COALESCE(pf.total_movies - pf.movies_with_notes, 0) AS movies_without_notes
FROM 
    PersonFeatures pf
JOIN 
    aka_name p ON pf.person_id = p.person_id
JOIN 
    TitleStatistics ps ON ps.movie_count >= 5
ORDER BY 
    ps.production_year DESC, 
    p.name;
