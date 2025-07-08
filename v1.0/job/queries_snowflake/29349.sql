
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        COUNT(DISTINCT mk.keyword_id) AS num_keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.num_companies,
        rt.num_keywords
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5
)

SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    COUNT(ci.person_role_id) AS num_roles,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.title_id = cc.movie_id
JOIN 
    cast_info ci ON ci.id = cc.subject_id
JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = tm.title_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.title_id, ak.name, tm.title, tm.production_year, tm.num_companies, tm.num_keywords
ORDER BY 
    tm.production_year DESC, tm.num_keywords DESC;
