WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title AS a
    JOIN 
        movie_info AS m ON a.id = m.movie_id
    JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    JOIN 
        cast_info AS c ON a.id = c.movie_id
    JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre') 
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Action%')
    GROUP BY 
        a.id, a.title, a.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5 -- Movies with more than 5 cast members
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        RANK() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies AS rm
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    ak.name AS known_aliases,
    ct.kind AS company_type,
    GROUP_CONCAT(DISTINCT cn.name SEPARATOR ', ') AS companies
FROM 
    TopMovies AS tm
LEFT JOIN 
    movie_companies AS mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
WHERE 
    tm.rank <= 10 -- Top 10 movies with the highest cast counts
GROUP BY 
    tm.title, tm.production_year, tm.cast_count, ak.name, ct.kind
ORDER BY 
    tm.cast_count DESC;
