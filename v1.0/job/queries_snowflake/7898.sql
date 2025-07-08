
WITH ranked_movies AS (
    SELECT 
        a.title, 
        a.production_year, 
        c.name AS company_name, 
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn 
    FROM 
        aka_title a 
    JOIN 
        movie_companies mc ON a.id = mc.movie_id 
    JOIN 
        company_name c ON mc.company_id = c.id 
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    WHERE 
        a.production_year >= 2000 
    GROUP BY 
        a.title, a.production_year, c.name 
), filtered_movies AS (
    SELECT 
        title, 
        production_year, 
        company_name, 
        keywords 
    FROM 
        ranked_movies 
    WHERE 
        rn <= 5 
) 
SELECT 
    fm.title, 
    fm.production_year, 
    fm.company_name, 
    fm.keywords 
FROM 
    filtered_movies fm 
ORDER BY 
    fm.production_year DESC, 
    fm.title;
