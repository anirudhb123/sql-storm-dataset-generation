WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_year
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),

MostPopularTitles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.total_cast
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank_year <= 5
),

MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        group_concat(DISTINCT ak.name) AS actors,
        group_concat(DISTINCT sup.name) AS production_companies
    FROM 
        MostPopularTitles mt
    LEFT JOIN 
        complete_cast cc ON mt.title = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name sup ON mc.company_id = sup.id
    GROUP BY 
        mt.title, mt.production_year
)

SELECT 
    title,
    production_year,
    actors,
    production_companies
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, total_cast DESC;
