
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL 
        AND t.title IS NOT NULL
),
CastWithRoles AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        cp.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        comp_cast_type cp ON c.person_role_id = cp.id
),
MoviesWithCompany AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(cn.name, 'Unknown') AS company_name,
        ARRAY_AGG(DISTINCT kt.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        m.id, m.title, cn.name
)
SELECT 
    rt.title, 
    rt.production_year,
    COUNT(DISTINCT cwr.person_id) AS total_cast_count,
    COUNT(DISTINCT mwc.movie_id) AS total_movies,
    LISTAGG(DISTINCT mwc.company_name, ', ') WITHIN GROUP (ORDER BY mwc.company_name) AS production_companies
FROM 
    RankedTitles rt
LEFT JOIN 
    CastWithRoles cwr ON rt.title_id = cwr.movie_id AND cwr.role_rank <= 3  
LEFT JOIN 
    MoviesWithCompany mwc ON rt.title_id = mwc.movie_id
WHERE 
    rt.rank <= 5  
GROUP BY 
    rt.title, rt.production_year
HAVING 
    COUNT(DISTINCT cwr.person_id) > 0
    AND COUNT(DISTINCT mwc.movie_id) > 1  
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC 
LIMIT 10;
