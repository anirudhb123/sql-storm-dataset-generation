WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS company_type,
        COUNT(DISTINCT ca.person_id) AS number_of_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    GROUP BY 
        t.title, t.production_year, k.keyword, c.kind
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.company_type,
        rm.number_of_cast_members
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.company_type,
    tm.number_of_cast_members,
    COALESCE(ARRAY_AGG(DISTINCT p.first_name || ' ' || p.last_name), '{}'::text[]) AS cast_members
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
LEFT JOIN 
    aka_name p ON ci.person_id = p.person_id
GROUP BY 
    tm.title, tm.production_year, tm.keyword, tm.company_type, tm.number_of_cast_members
ORDER BY 
    tm.production_year DESC, tm.number_of_cast_members DESC;

This SQL query benchmarks string processing by focusing on the string attributes derived from various entities in the Join Order Benchmark schema. It ranks movies based on the number of cast members per year, retrieving only the top 5 for each year, while also grouping, joining, and concatenating details about the movies and their cast.
