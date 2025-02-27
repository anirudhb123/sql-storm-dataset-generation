WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
HighProfilePeople AS (
    SELECT 
        p.id AS person_id,
        p.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name p
    LEFT JOIN 
        cast_info ci ON p.person_id = ci.person_id
    GROUP BY 
        p.id, p.name
    HAVING 
        COUNT(ci.movie_id) > 10
),
TopMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        r.movie_count
    FROM 
        RankedTitles r
    JOIN 
        aka_title m ON r.title_id = m.id
    WHERE 
        r.year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    cpp.name AS producer_name,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name cpp ON mc.company_id = cpp.id AND cpp.country_code = 'USA'
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    tm.title, tm.production_year, cpp.name
ORDER BY 
    tm.production_year DESC, total_cast DESC;
