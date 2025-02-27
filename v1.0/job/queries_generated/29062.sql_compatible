
WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT p.info, ', ') AS person_info
    FROM title t
    LEFT JOIN aka_title at ON t.id = at.movie_id
    LEFT JOIN aka_name ak ON at.id = ak.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name co ON mc.company_id = co.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = t.id
    LEFT JOIN person_info p ON ci.person_id = p.person_id
    WHERE 
        t.production_year > 2000
        AND k.keyword IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    title,
    production_year,
    aka_names,
    company_names,
    keywords,
    person_info
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, 
    title;
