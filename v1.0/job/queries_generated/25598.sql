WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        r.role AS cast_role,
        k.keyword AS movie_keyword,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.title, a.production_year, r.role, k.keyword
), 
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_role,
        movie_keyword,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY movie_keyword ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    f.movie_title,
    f.production_year,
    f.cast_role,
    f.movie_keyword,
    f.cast_count
FROM 
    FilteredMovies f
JOIN 
    aka_name n ON n.md5sum = (SELECT md5sum FROM aka_name WHERE name ILIKE '%' || f.cast_role || '%')
WHERE 
    f.rank <= 5
ORDER BY 
    f.movie_keyword, f.cast_count DESC;
