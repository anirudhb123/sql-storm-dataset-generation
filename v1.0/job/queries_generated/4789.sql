WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY m.company_id DESC) AS rank,
        COALESCE(k.keyword, 'Unknown') AS movie_keyword
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies m ON a.id = m.movie_id
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        movie_keyword 
    FROM 
        RankedMovies
    WHERE 
        rank = 1
    ORDER BY 
        production_year DESC
)
SELECT 
    T.title,
    T.production_year,
    CASE 
        WHEN P.info IS NOT NULL THEN P.info 
        ELSE 'No additional info' 
    END AS additional_info,
    C.kind AS company_type,
    COUNT(DISTINCT CA.person_id) AS total_cast,
    STRING_AGG(DISTINCT N.name, ', ') AS cast_names
FROM 
    TopMovies T
LEFT JOIN 
    complete_cast CC ON T.title = (SELECT title FROM aka_title WHERE id = CC.movie_id) 
LEFT JOIN 
    cast_info CA ON CC.movie_id = CA.movie_id
LEFT JOIN 
    person_info P ON CA.person_id = P.person_id AND P.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
JOIN 
    movie_companies MC ON MC.movie_id = T.id
JOIN 
    company_type C ON MC.company_type_id = C.id
LEFT JOIN 
    aka_name N ON N.person_id = CA.person_id
GROUP BY 
    T.title, T.production_year, P.info, C.kind
ORDER BY 
    T.production_year DESC, total_cast DESC;
