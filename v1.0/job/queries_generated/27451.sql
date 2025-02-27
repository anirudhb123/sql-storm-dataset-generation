WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT c.role_id ORDER BY c.role_id) AS cast_roles
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalBenchmark AS (
    SELECT 
        md.movie_id,
        md.title AS movie_title,
        md.production_year,
        md.aka_names,
        kd.keywords,
        (SELECT GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind)
         FROM movie_companies mc
         JOIN company_type c ON mc.company_type_id = c.id
         WHERE mc.movie_id = md.movie_id) AS company_types
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordDetails kd ON md.movie_id = kd.movie_id
)
SELECT 
    fb.movie_id,
    fb.movie_title,
    fb.production_year,
    fb.aka_names,
    fb.keywords,
    fb.company_types
FROM 
    FinalBenchmark fb
WHERE 
    fb.production_year >= 2000
ORDER BY 
    fb.production_year DESC, 
    fb.movie_title;
