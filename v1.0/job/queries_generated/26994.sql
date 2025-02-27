WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast_members
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast_members
    FROM 
        RankedMovies
    WHERE 
        production_year BETWEEN 2000 AND 2023
    ORDER BY 
        total_cast_members DESC
    LIMIT 10
),
KeywordRankings AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.production_year,
        k.keyword,
        pk.keyword_count
    FROM 
        TopMovies pm
    JOIN 
        PopularKeywords pk ON pm.movie_id = pk.movie_id
    ORDER BY 
        pm.total_cast_members DESC, 
        pk.keyword_count DESC
)
SELECT 
    kr.movie_id,
    kr.title,
    kr.production_year,
    kr.keyword
FROM 
    KeywordRankings kr
JOIN 
    aka_name an ON an.person_id IN (SELECT DISTINCT person_id FROM cast_info WHERE movie_id = kr.movie_id)
WHERE 
    an.name LIKE '%Smith%'
ORDER BY 
    kr.production_year DESC, 
    kr.keyword;
