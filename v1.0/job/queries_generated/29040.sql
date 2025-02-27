WITH MovieData AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
        COALESCE(cn.name, 'Unknown Company') AS production_company
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name ak ON at.id = ak.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        t.id, cn.name
),
CastData AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        GROUP_CONCAT(DISTINCT p.name ORDER BY p.name) AS cast_names
    FROM 
        complete_cast c
    JOIN 
        cast_info ci ON c.movie_id = ci.movie_id
    JOIN 
        name p ON ci.person_id = p.id
    GROUP BY 
        c.movie_id
),
FinalReport AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.aka_names,
        md.keywords,
        md.production_company,
        cd.total_cast,
        cd.cast_names
    FROM 
        MovieData md
    LEFT JOIN 
        CastData cd ON md.title_id = cd.movie_id
)
SELECT 
    movie_title,
    production_year,
    aka_names,
    keywords,
    production_company,
    total_cast,
    cast_names
FROM 
    FinalReport
ORDER BY 
    production_year DESC, movie_title;
