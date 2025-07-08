
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_count
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast_count <= 10
)

SELECT 
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    tm.cast_count AS Cast_Count,
    tm.actor_names AS Main_Actors,
    ct.kind AS Company_Type,
    cn.name AS Company_Name,
    mi.info AS Movie_Info
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.title_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON tm.title_id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
