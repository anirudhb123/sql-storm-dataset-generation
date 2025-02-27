WITH movie_characteristics AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.kind) AS company_types,
        GROUP_CONCAT(DISTINCT n.gender) AS cast_genders,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        name n ON ci.person_id = n.imdb_id  -- Assuming the use of 'imdb_id' for linking names
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
company_summary AS (
    SELECT 
        company_id,
        COUNT(DISTINCT movie_id) AS movies_count,
        STRING_AGG(DISTINCT ct.kind, ', ') AS types,
        STRING_AGG(DISTINCT cn.name, ', ') AS names
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        company_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.aka_names,
    mh.keywords,
    mh.company_types,
    mh.cast_count,
    cs.movies_count AS affiliated_movies_count,
    cs.types AS company_types_summary,
    cs.names AS companies_involved
FROM 
    movie_characteristics mh
LEFT JOIN 
    company_summary cs ON mh.movie_id IN (SELECT movie_id FROM movie_companies WHERE company_id IN (SELECT DISTINCT company_id FROM company_name))
ORDER BY 
    mh.production_year DESC, mh.title;
