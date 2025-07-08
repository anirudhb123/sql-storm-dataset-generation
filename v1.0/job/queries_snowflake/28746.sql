
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        COUNT(ci.person_id) AS total_cast,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS rn
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year, ak.name
    HAVING 
        COUNT(ci.person_id) >= 5
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        actor_name,
        total_cast,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rn = 1
    ORDER BY 
        total_cast DESC
    LIMIT 10
)
SELECT 
    fm.title AS Movie_Title,
    fm.production_year AS Release_Year,
    fm.actor_name AS Lead_Actor,
    fm.total_cast AS Total_Cast_Count,
    fm.keywords AS Associated_Keywords
FROM 
    FilteredMovies fm
JOIN 
    movie_info mi ON mi.movie_id = (SELECT id FROM aka_title WHERE title = fm.title AND production_year = fm.production_year LIMIT 1)
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
ORDER BY 
    fm.production_year DESC;
