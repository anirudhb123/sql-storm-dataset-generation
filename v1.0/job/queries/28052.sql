WITH filtered_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
        AND k.keyword ILIKE '%action%'
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        count(DISTINCT ci.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movies_with_cast AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        cs.total_cast_members,
        cs.cast_names
    FROM 
        filtered_movies fm
    LEFT JOIN 
        cast_summary cs ON fm.movie_id = cs.movie_id
)

SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    mwc.total_cast_members,
    mwc.cast_names,
    STRING_AGG(DISTINCT cct.kind, ', ') AS company_types
FROM 
    movies_with_cast mwc
LEFT JOIN 
    movie_companies mc ON mwc.movie_id = mc.movie_id
LEFT JOIN 
    company_type cct ON mc.company_type_id = cct.id
GROUP BY 
    mwc.movie_id, mwc.title, mwc.production_year, mwc.total_cast_members, mwc.cast_names
ORDER BY 
    mwc.production_year DESC, mwc.title;
