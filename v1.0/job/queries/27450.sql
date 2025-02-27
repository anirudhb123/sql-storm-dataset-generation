WITH RankedTitles AS (
    SELECT 
        a.title, 
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS year_rank
    FROM
        aka_title a
    JOIN
        movie_keyword mk ON a.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
TopCast AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        ct.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    WHERE 
        c.nr_order IS NOT NULL
)
SELECT 
    rt.title AS Movie_Title,
    rt.production_year AS Production_Year,
    rt.keyword AS Keyword,
    tc.actor_name AS Actor_Name,
    tc.role_type AS Role_Type
FROM 
    RankedTitles rt
JOIN 
    TopCast tc ON rt.year_rank = tc.cast_rank
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
