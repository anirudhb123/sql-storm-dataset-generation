WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.imdb_index,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast_details
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
company_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS total_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS companies_involved
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
full_summary AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.keyword,
        mh.keyword_rank,
        cs.total_cast,
        cs.cast_details,
        coalesce(comp.total_companies, 0) AS total_companies,
        comp.companies_involved
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        company_summary comp ON mh.movie_id = comp.movie_id
)
SELECT 
    fs.movie_id,
    fs.movie_title,
    fs.production_year,
    fs.keyword,
    fs.keyword_rank,
    fs.total_cast,
    fs.cast_details,
    fs.total_companies,
    fs.companies_involved,
    CASE 
        WHEN fs.total_companies IS NULL THEN 'No company associated'
        WHEN fs.total_companies = 0 THEN 'Independent film'
        ELSE 'Produced by multiple companies'
    END AS company_status
FROM 
    full_summary fs
WHERE 
    fs.keyword_rank <= 3 OR (fs.production_year IS NULL AND fs.total_cast > 5)
ORDER BY 
    fs.movie_title DESC,
    fs.production_year DESC;
