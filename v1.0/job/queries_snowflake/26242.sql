
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        a.name AS person_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
HighRatedMovies AS (
    SELECT 
        rt.person_name,
        rt.movie_title,
        rt.production_year,
        COUNT(DISTINCT mc.movie_id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        RankedTitles rt
    JOIN 
        complete_cast cc ON rt.title_id = cc.movie_id
    JOIN 
        movie_companies mc ON mc.movie_id = rt.title_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        rt.rank = 1
    GROUP BY 
        rt.person_name, rt.movie_title, rt.production_year
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 1
)
SELECT 
    h.person_name,
    h.movie_title,
    h.production_year,
    h.company_count,
    h.companies
FROM 
    HighRatedMovies h
ORDER BY 
    h.production_year DESC, h.person_name;
