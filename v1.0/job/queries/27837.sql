WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast_list,
        COUNT(mk.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.id) DESC) AS rank_by_keywords
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_list, 
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank_by_keywords <= 10
)

SELECT 
    f.title,
    f.production_year,
    f.cast_list,
    f.keyword_count,
    COALESCE(cn.name, 'No Company') AS company_name,
    ct.kind AS company_type
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    f.keyword_count DESC,
    f.production_year ASC;