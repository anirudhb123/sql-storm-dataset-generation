WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY t.id, t.title, t.production_year
),
DistinctDirectors AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT COALESCE(d.name, 'Unknown')) AS director_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        aka_name d ON cn.imdb_id = d.person_id AND ct.kind = 'director'
    GROUP BY c.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        dd.director_count
    FROM 
        RankedMovies rm
    JOIN 
        DistinctDirectors dd ON rm.movie_id = dd.movie_id
    WHERE 
        rank <= 10 AND 
        rm.production_year >= 2000
)
SELECT 
    fm.title,
    fm.production_year,
    fm.director_count,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
GROUP BY 
    fm.title, 
    fm.production_year, 
    fm.director_count
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    fm.production_year DESC, 
    fm.director_count DESC;
