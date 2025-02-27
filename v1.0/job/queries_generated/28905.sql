WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
    FROM 
        aka_title t
        LEFT JOIN movie_keyword mk ON t.movie_id = mk.movie_id
        LEFT JOIN keyword kw ON mk.keyword_id = kw.id
        LEFT JOIN movie_companies mc ON t.movie_id = mc.movie_id
        LEFT JOIN company_name cn ON mc.company_id = cn.id
        LEFT JOIN aka_name ak ON t.title ILIKE '%' || ak.name || '%' -- Fuzzy match for aka names
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

CastDetails AS (
    SELECT 
        t.id AS movie_id,
        GROUP_CONCAT(DISTINCT p.name ORDER BY p.name) AS cast_members,
        COUNT(DISTINCT c.person_role_id) AS role_count
    FROM 
        title t
        LEFT JOIN cast_info c ON t.id = c.movie_id
        LEFT JOIN name p ON c.person_id = p.imdb_id
    GROUP BY 
        t.id
),

FinalReport AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.aka_names,
        md.company_names,
        md.keywords,
        cd.cast_members,
        cd.role_count
    FROM 
        MovieDetails md
        LEFT JOIN CastDetails cd ON md.movie_id = cd.movie_id
    ORDER BY 
        md.production_year DESC, 
        md.title ASC
)

SELECT 
    * 
FROM 
    FinalReport 
LIMIT 100;
