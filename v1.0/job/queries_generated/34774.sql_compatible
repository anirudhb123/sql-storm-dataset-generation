
WITH RECURSIVE MovieRanks AS (
    SELECT 
        ct.id AS movie_id,
        ct.title AS title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY ct.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank,
        ct.production_year
    FROM 
        aka_title ct
    LEFT JOIN 
        cast_info ci ON ct.movie_id = ci.movie_id
    GROUP BY 
        ct.id, ct.title, ct.production_year
),
RecentMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COALESCE(COUNT(mk.keyword_id), 0) AS keyword_count,
        COALESCE(SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS has_trivia
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info pi ON a.movie_id = pi.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
HighRankedMovies AS (
    SELECT 
        mr.movie_id,
        mr.title,
        mr.cast_count,
        mr.rank,
        rm.keyword_count,
        rm.has_trivia,
        rm.production_year
    FROM 
        MovieRanks mr
    JOIN 
        RecentMovies rm ON mr.movie_id = rm.movie_id
    WHERE 
        mr.rank <= 5
)
SELECT 
    hr.movie_id,
    hr.title,
    hr.cast_count,
    hr.keyword_count,
    CASE 
        WHEN hr.has_trivia > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_trivia
FROM 
    HighRankedMovies hr
ORDER BY 
    hr.production_year DESC, hr.cast_count DESC;
