WITH Recursive_CTE AS (
    SELECT 
        c.movie_id,
        c.person_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_order,
        COALESCE(a.name, 'Unknown') AS actor_name
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
Movie_Cast AS (
    SELECT 
        rc.movie_id,
        STRING_AGG(rc.actor_name, ', ') AS full_cast
    FROM 
        Recursive_CTE rc
    GROUP BY 
        rc.movie_id
),
Movie_Keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
Movie_Companies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        MAX(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS has_production_company
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
Filtered_Movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mc.full_cast,
        mk.keywords,
        m.company_count,
        m.has_production_company
    FROM 
        title t
    LEFT JOIN 
        Movie_Cast mc ON t.id = mc.movie_id
    LEFT JOIN 
        Movie_Keywords mk ON t.id = mk.movie_id
    LEFT JOIN 
        Movie_Companies m ON t.id = m.movie_id
    WHERE 
        t.production_year >= 2000
        AND (m.has_production_company = 1 OR m.company_count IS NULL)
)
SELECT 
    movie_id,
    title,
    production_year,
    COALESCE(full_cast, 'No cast available') AS full_cast,
    COALESCE(keywords, 'No keywords available') AS keywords,
    company_count,
    CASE 
        WHEN has_production_company = 1 THEN 'Yes' 
        ELSE 'No' 
    END AS has_production
FROM 
    Filtered_Movies
ORDER BY 
    production_year DESC, title;
