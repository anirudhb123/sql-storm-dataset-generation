WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.kind) AS company_types,
        COUNT(DISTINCT m.id) AS num_companies,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularTitles AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.keywords,
        rm.company_types,
        rm.num_companies,
        mt.info AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info_idx mt ON rm.movie_id = mt.movie_id
    WHERE 
        rm.num_companies > 5
)
SELECT 
    pt.movie_id,
    pt.movie_title,
    pt.production_year,
    pt.keywords,
    pt.company_types,
    pt.movie_info,
    COUNT(DISTINCT c.id) AS cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names
FROM 
    PopularTitles pt
LEFT JOIN 
    cast_info c ON pt.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    pt.movie_id, pt.movie_title, pt.production_year, pt.keywords, pt.company_types, pt.movie_info
ORDER BY 
    pt.production_year DESC, pt.movie_title;
